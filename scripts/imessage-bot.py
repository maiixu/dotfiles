#!/usr/bin/env python3
"""
iMessage bot: polls ~/Library/Messages/chat.db for new messages from a specified
phone number, invokes `claude --print`, and replies via osascript.

State: ~/.imessage-bot-state.json (tracks last seen ROWID)

Requirements:
  - Terminal must have Full Disk Access (Privacy & Security → Full Disk Access)
  - Messages.app signed in with Apple ID + iMessage activated
  - Terminal granted Automation access to Messages (Privacy → Automation)
  - IMESSAGE_PHONE set in environment (e.g. +15551234567)
"""

import json
import os
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


def _get_apple_id_email() -> str:
    """Detect the Apple ID email for this Mac from system preferences."""
    try:
        result = subprocess.run(
            ["defaults", "read", "MobileMeAccounts"],
            capture_output=True, text=True
        )
        import re
        m = re.search(r'AccountID = "([^"]+)"', result.stdout)
        return m.group(1) if m else ""
    except Exception:
        return ""

MY_EMAIL = os.environ.get("IMESSAGE_EMAIL") or _env.get("IMESSAGE_EMAIL", "") or _get_apple_id_email()

# Guard against iCloud-reflected copies of our own replies appearing as inbound.
# Keeps the last N reply texts; if a "received" message matches, skip it.
_recent_sent: list[str] = []
_RECENT_SENT_MAX = 10


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_rowid": 0}


def save_state(state: dict):
    STATE_FILE.write_text(json.dumps(state))


def get_new_messages(last_rowid: int) -> list[tuple]:
    """Return list of (rowid, text) for new inbound messages from MY_PHONE.

    Detects two delivery paths:
    1. Direct iMessage receipt: is_from_me=0, handle=MY_PHONE
    2. iCloud Messages sync fallback: is_from_me=1 in the chat addressed to
       MY_EMAIL (user sent from iPhone → synced to Mac as a 'sent' entry)
    """
    # chat.db uses WAL mode; copy all three files so SQLite can read WAL entries
    import tempfile as _tempfile
    tmp_dir = Path(_tempfile.mkdtemp())
    tmp_path = tmp_dir / "chat.db"
    try:
        shutil.copy2(DB_PATH, tmp_path)
        for ext in ("-wal", "-shm"):
            src = DB_PATH.parent / (DB_PATH.name + ext)
            if src.exists():
                shutil.copy2(src, tmp_dir / (tmp_path.name + ext))
        conn = sqlite3.connect(str(tmp_path))

        # Path 1: direct delivery
        direct = conn.execute(
            """
            SELECT m.ROWID, m.text
            FROM message m
            JOIN handle h ON m.handle_id = h.ROWID
            WHERE h.id = ?
              AND m.ROWID > ?
              AND m.is_from_me = 0
            ORDER BY m.ROWID
            """,
            (MY_PHONE, last_rowid),
        ).fetchall()

        # Path 2: iCloud sync fallback (is_from_me=1 in the MY_EMAIL chat)
        icloud = []
        if MY_EMAIL:
            icloud = conn.execute(
                """
                SELECT m.ROWID, m.text
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

    # Merge, deduplicate, sort
    seen = set()
    merged = []
    for row in sorted(direct + icloud, key=lambda r: r[0]):
        if row[0] not in seen:
            seen.add(row[0])
            merged.append(row)
    return merged


def send_imessage(text: str):
    global _recent_sent
    _recent_sent.append(text)
    if len(_recent_sent) > _RECENT_SENT_MAX:
        _recent_sent = _recent_sent[-_RECENT_SENT_MAX:]
    # Escape for AppleScript string literal
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    script = f'''tell application "Messages"
  set targetService to 1st service whose service type = iMessage
  set b to buddy "{MY_PHONE}" of targetService
  send "{escaped}" to b
end tell'''
    subprocess.run(["osascript", "-e", script], check=False)


BOT_DIR = Path.home() / "code" / "claude-bot"


def invoke_claude(prompt: str) -> str:
    result = subprocess.run(
        ["claude", "--print", prompt],
        capture_output=True,
        text=True,
        timeout=180,
        cwd=str(BOT_DIR) if BOT_DIR.exists() else None,
    )
    return result.stdout.strip() or result.stderr.strip() or "(no response)"


def main():
    if not MY_PHONE:
        raise RuntimeError("IMESSAGE_PHONE env var not set")

    print(f"iMessage bot started, watching messages from {MY_PHONE} (email: {MY_EMAIL or 'not detected'})")
    state = load_state()
    last_rowid = state["last_rowid"]

    # On first run, initialize last_rowid to current max so we don't replay history
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
            for rowid, text in rows:
                if text and text.strip():
                    if text in _recent_sent:
                        print(f"Skipped [{rowid}] (iCloud reflection of own reply)")
                    else:
                        print(f"Received [{rowid}]: {text[:80]}")
                        reply = invoke_claude(text.strip())
                        send_imessage(reply)
                        print(f"Replied [{rowid}]: {reply[:80]}")
                last_rowid = rowid
            if rows:
                save_state({"last_rowid": last_rowid})
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
