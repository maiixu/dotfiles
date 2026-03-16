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


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_rowid": 0}


def save_state(state: dict):
    STATE_FILE.write_text(json.dumps(state))


def get_new_messages(last_rowid: int) -> list[tuple]:
    """Return list of (rowid, text) for new inbound messages from MY_PHONE."""
    # chat.db is locked by Messages; work on a copy
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        tmp_path = f.name
    try:
        shutil.copy2(DB_PATH, tmp_path)
        conn = sqlite3.connect(tmp_path)
        rows = conn.execute(
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
        conn.close()
    finally:
        Path(tmp_path).unlink(missing_ok=True)
    return rows


def send_imessage(text: str):
    # Escape for AppleScript string literal
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    script = f'''tell application "Messages"
  set b to buddy "{MY_PHONE}" of service "iMessage"
  send "{escaped}" to b
end tell'''
    subprocess.run(["osascript", "-e", script], check=False)


def invoke_claude(prompt: str) -> str:
    result = subprocess.run(
        ["claude", "--print", prompt],
        capture_output=True,
        text=True,
        timeout=180,
    )
    return result.stdout.strip() or result.stderr.strip() or "(no response)"


def main():
    if not MY_PHONE:
        raise RuntimeError("IMESSAGE_PHONE env var not set")

    print(f"iMessage bot started, watching messages from {MY_PHONE}")
    state = load_state()
    last_rowid = state["last_rowid"]

    # On first run, initialize last_rowid to current max so we don't replay history
    if last_rowid == 0 and DB_PATH.exists():
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            tmp_path = f.name
        try:
            shutil.copy2(DB_PATH, tmp_path)
            conn = sqlite3.connect(tmp_path)
            row = conn.execute("SELECT MAX(ROWID) FROM message").fetchone()
            conn.close()
            last_rowid = row[0] or 0
        finally:
            Path(tmp_path).unlink(missing_ok=True)
        save_state({"last_rowid": last_rowid})
        print(f"Initialized at ROWID={last_rowid}")

    while True:
        try:
            rows = get_new_messages(last_rowid)
            for rowid, text in rows:
                if text and text.strip():
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
