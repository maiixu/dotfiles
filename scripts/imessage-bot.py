#!/usr/bin/env python3
"""
iMessage bot: polls ~/Library/Messages/chat.db for new messages from a specified
phone number, invokes `claude --print`, and replies via osascript.

State: ~/.imessage-bot-state.json (tracks last seen ROWID)
History: ~/code/claude-bot/conversations.jsonl (rolling 100-message window)

Requirements:
  - Terminal must have Full Disk Access (Privacy & Security → Full Disk Access)
  - Messages.app signed in with Apple ID + iMessage activated
  - Terminal granted Automation access to Messages (Privacy → Automation)
  - IMESSAGE_PHONE set in environment (e.g. +15551234567)
"""

import json
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
import time
from pathlib import Path

def _load_env_file() -> dict:
    env_file = Path.home() / ".env"
    result = {}
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                result[k.strip()] = v.strip()
    return result

_env = _load_env_file()
MY_PHONE = os.environ.get("IMESSAGE_PHONE") or _env.get("IMESSAGE_PHONE", "")
STATE_FILE = Path.home() / ".imessage-bot-state.json"
DB_PATH = Path.home() / "Library/Messages/chat.db"
POLL_INTERVAL = 10  # seconds
BOT_DIR = Path.home() / "code" / "claude-bot"
HISTORY_FILE = BOT_DIR / "conversations.jsonl"
HISTORY_MAX = 100


def _get_apple_id_email() -> str:
    try:
        result = subprocess.run(
            ["defaults", "read", "MobileMeAccounts"],
            capture_output=True, text=True
        )
        m = re.search(r'AccountID = "([^"]+)"', result.stdout)
        return m.group(1) if m else ""
    except Exception:
        return ""

MY_EMAIL = os.environ.get("IMESSAGE_EMAIL") or _env.get("IMESSAGE_EMAIL", "") or _get_apple_id_email()

# Guard against iCloud-reflected copies of our own replies appearing as inbound.
_recent_sent: list[str] = []
_RECENT_SENT_MAX = 10


# ── History ──────────────────────────────────────────────────────────────────

def history_append(role: str, content: str):
    """Append one turn to the rolling conversation log."""
    BOT_DIR.mkdir(parents=True, exist_ok=True)
    entry = {"role": role, "content": content, "ts": int(time.time())}
    with HISTORY_FILE.open("a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")
    _history_trim()


def _history_trim():
    """Keep only the last HISTORY_MAX lines."""
    if not HISTORY_FILE.exists():
        return
    lines = HISTORY_FILE.read_text().splitlines()
    if len(lines) > HISTORY_MAX:
        HISTORY_FILE.write_text("\n".join(lines[-HISTORY_MAX:]) + "\n")


def history_load() -> list[dict]:
    if not HISTORY_FILE.exists():
        return []
    entries = []
    for line in HISTORY_FILE.read_text().splitlines():
        line = line.strip()
        if line:
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return entries[-HISTORY_MAX:]


# ── DB polling ────────────────────────────────────────────────────────────────

def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_rowid": 0}


def save_state(state: dict):
    STATE_FILE.write_text(json.dumps(state))


def get_new_messages(last_rowid: int) -> list[tuple]:
    """Return list of (rowid, text, audio_path) for new inbound messages.

    text is None for audio-only messages; audio_path is None for text messages.
    Detects two delivery paths:
    1. Direct iMessage receipt: is_from_me=0, handle=MY_PHONE
    2. iCloud Messages sync fallback: is_from_me=1 in the chat addressed to
       MY_EMAIL (user sent from iPhone → synced to Mac as a 'sent' entry)
    """
    tmp_dir = Path(tempfile.mkdtemp())
    tmp_path = tmp_dir / "chat.db"
    try:
        shutil.copy2(DB_PATH, tmp_path)
        for ext in ("-wal", "-shm"):
            src = DB_PATH.parent / (DB_PATH.name + ext)
            if src.exists():
                shutil.copy2(src, tmp_dir / (tmp_path.name + ext))
        conn = sqlite3.connect(str(tmp_path))

        base_select = """
            SELECT m.ROWID, m.text,
                   (SELECT a.filename FROM attachment a
                    JOIN message_attachment_join maj ON a.ROWID = maj.attachment_id
                    WHERE maj.message_id = m.ROWID
                      AND (a.mime_type LIKE 'audio/%'
                           OR a.transfer_name LIKE '%.caf'
                           OR a.transfer_name LIKE '%.m4a')
                    LIMIT 1) AS audio_path
        """

        direct = conn.execute(
            base_select + """
            FROM message m
            JOIN handle h ON m.handle_id = h.ROWID
            WHERE h.id = ?
              AND m.ROWID > ?
              AND m.is_from_me = 0
            ORDER BY m.ROWID
            """,
            (MY_PHONE, last_rowid),
        ).fetchall()

        icloud = []
        if MY_EMAIL:
            icloud = conn.execute(
                base_select + """
                FROM message m
                JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
                JOIN chat c ON cmj.chat_id = c.ROWID
                WHERE c.chat_identifier = ?
                  AND m.ROWID > ?
                  AND m.is_from_me = 1
                ORDER BY m.ROWID
                """,
                (MY_EMAIL, last_rowid),
            ).fetchall()

        conn.close()
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

    seen = set()
    merged = []
    for row in sorted(direct + icloud, key=lambda r: r[0]):
        if row[0] not in seen:
            seen.add(row[0])
            # Tag source: direct messages → phone, icloud sync → email
            source = "phone" if row in direct else "email"
            merged.append((*row, source))
    return merged  # [(rowid, text, audio_path, source), ...]


# ── Sending & invoking Claude ─────────────────────────────────────────────────

WHISPER_CLI = "/opt/homebrew/bin/whisper-cli"
WHISPER_MODEL = str(Path.home() / "whisper-models" / "ggml-large-v3-turbo-q5_0.bin")


def transcribe_audio(raw_path: str) -> str:
    """Transcribe an iMessage audio attachment using whisper.cpp."""
    path = raw_path.replace("~/", str(Path.home()) + "/")
    if not Path(path).exists():
        print(f"Audio file not found: {path}")
        return ""
    # whisper-cli only supports wav/mp3/flac/ogg; convert CAF → WAV via ffmpeg
    tmp_dir = Path(tempfile.mkdtemp())
    try:
        wav_path = tmp_dir / "audio.wav"
        subprocess.run(
            ["ffmpeg", "-i", path, "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le",
             str(wav_path)],
            capture_output=True, check=True, timeout=30,
        )
        result = subprocess.run(
            [WHISPER_CLI, "-m", WHISPER_MODEL, "-l", "auto",
             "--no-timestamps", "-of", str(tmp_dir / "out"), str(wav_path)],
            capture_output=True, text=True, timeout=120,
        )
        out_txt = tmp_dir / "out.txt"
        if out_txt.exists():
            return out_txt.read_text().strip()
        # fallback: parse stdout
        return result.stdout.strip()
    except Exception as e:
        print(f"Transcription error: {e}")
        return ""
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def send_imessage(text: str, target: str | None = None):
    global _recent_sent
    _recent_sent.append(text)
    if len(_recent_sent) > _RECENT_SENT_MAX:
        _recent_sent = _recent_sent[-_RECENT_SENT_MAX:]
    buddy_id = target or MY_PHONE
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    script = f'''tell application "Messages"
  set targetService to 1st service whose service type = iMessage
  set b to buddy "{buddy_id}" of targetService
  send "{escaped}" to b
end tell'''
    subprocess.run(["osascript", "-e", script], check=False)


def invoke_claude(user_message: str) -> str:
    history = history_load()
    if history:
        lines = []
        for h in history:
            speaker = "Mai" if h["role"] == "user" else "Claude"
            lines.append(f"{speaker}: {h['content']}")
        context = "\n".join(lines)
        prompt = f"Recent conversation:\n{context}\n\nMai: {user_message}"
    else:
        prompt = user_message

    result = subprocess.run(
        ["claude", "--print", "--dangerously-skip-permissions", prompt],
        capture_output=True,
        text=True,
        timeout=180,
        cwd=str(BOT_DIR) if BOT_DIR.exists() else None,
    )
    return result.stdout.strip() or result.stderr.strip() or "(no response)"


# ── Main loop ─────────────────────────────────────────────────────────────────

def main():
    if not MY_PHONE:
        raise RuntimeError("IMESSAGE_PHONE env var not set")

    print(f"iMessage bot started, watching messages from {MY_PHONE} (email: {MY_EMAIL or 'not detected'})")
    state = load_state()
    last_rowid = state["last_rowid"]

    if last_rowid == 0 and DB_PATH.exists():
        tmp_dir = Path(tempfile.mkdtemp())
        tmp_path = tmp_dir / "chat.db"
        try:
            shutil.copy2(DB_PATH, tmp_path)
            for ext in ("-wal", "-shm"):
                src = DB_PATH.parent / (DB_PATH.name + ext)
                if src.exists():
                    shutil.copy2(src, tmp_dir / (tmp_path.name + ext))
            conn = sqlite3.connect(str(tmp_path))
            row = conn.execute("SELECT MAX(ROWID) FROM message").fetchone()
            conn.close()
            last_rowid = row[0] or 0
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)
        save_state({"last_rowid": last_rowid})
        print(f"Initialized at ROWID={last_rowid}")

    while True:
        try:
            rows = get_new_messages(last_rowid)
            for rowid, text, audio_path, source in rows:
                # Determine reply target based on message source
                reply_target = MY_EMAIL if source == "email" else MY_PHONE

                # Transcribe audio if no text
                if not (text and text.strip()) and audio_path:
                    print(f"Transcribing audio [{rowid}]: {audio_path}")
                    text = transcribe_audio(audio_path)
                    if text:
                        print(f"Transcribed [{rowid}]: {text[:80]}")

                if text and text.strip():
                    if text in _recent_sent:
                        print(f"Skipped [{rowid}] (iCloud reflection of own reply)")
                    else:
                        print(f"Received [{rowid}] via {source}: {text[:80]}")
                        history_append("user", text.strip())
                        reply = invoke_claude(text.strip())
                        history_append("assistant", reply)
                        send_imessage(reply, target=reply_target)
                        print(f"Replied [{rowid}] to {reply_target}: {reply[:80]}")
                last_rowid = rowid
            if rows:
                save_state({"last_rowid": last_rowid})
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
