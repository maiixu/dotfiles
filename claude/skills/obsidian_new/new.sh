#!/usr/bin/env bash
# new_note.sh — create a new Obsidian inbox note
# Usage: new_note.sh "Title" "body content" "tags (one per line)"

set -euo pipefail

TITLE="${1:?Usage: new_note.sh <title> <body> <tags>}"
BODY="${2:-}"
TAGS="${3:-}"
TIMESTAMP=$(date +"%Y%m%d%H%M")
INBOX=~/notes/"收件箱 Inbox"
FILEPATH="${INBOX}/${TIMESTAMP} ${TITLE}.md"

TITLE="$TITLE" BODY="$BODY" TAGS="$TAGS" TIMESTAMP="$TIMESTAMP" FILEPATH="$FILEPATH" \
python3 << 'PYEOF'
import pathlib, os

title     = os.environ["TITLE"]
body      = os.environ["BODY"]
tags_raw  = os.environ["TAGS"]
timestamp = os.environ["TIMESTAMP"]
filepath  = os.environ["FILEPATH"]

path = pathlib.Path(filepath).expanduser()
path.parent.mkdir(parents=True, exist_ok=True)

tag_lines = "\n".join(
    "#" + t.lstrip("#") for t in tags_raw.strip().splitlines() if t.strip()
)
if tag_lines:
    tag_lines += "\n"

content = (
    "## " + title + "\n\n"
    + body + "\n\n"
    + "---\n"
    + timestamp + "\n\n"
    + tag_lines
    + "#Meta--元数据/Source--来源/Claude-Code\n"
)

path.write_text(content, encoding="utf-8")
print(f"Saved: {path.name}")
PYEOF

cd ~/notes && git add -A && git commit -m "inbox: ${TITLE}" && git push
