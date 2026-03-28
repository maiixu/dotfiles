#!/usr/bin/env bash
# new_note.sh — create a new Obsidian inbox note
# Usage: new_note.sh "Title" "body content" "tag1\ntag2..."
# Outputs the saved filename on success.

set -euo pipefail

TITLE="${1:?Usage: new_note.sh <title> <body> <tags>}"
BODY="${2:-}"
TAGS="${3:-}"

TIMESTAMP=$(date +"%Y%m%d%H%M")
INBOX=~/notes/"收件箱 Inbox"
FILEPATH="${INBOX}/${TIMESTAMP} ${TITLE}.md"

python3 << PYEOF
import pathlib

path = pathlib.Path("${FILEPATH}").expanduser()
path.parent.mkdir(parents=True, exist_ok=True)

tags = "\n".join(f"#{t.lstrip('#')}" for t in """${TAGS}""".strip().splitlines() if t.strip())
if tags:
    tags = "\n" + tags

content = f"""## ${TIMESTAMP} ${TITLE}

${BODY}

---
${TIMESTAMP}

{tags}
#Meta--元数据/Source--来源/Claude-Code
"""

path.write_text(content, encoding="utf-8")
print(f"Saved: {path.name}")
PYEOF

cd ~/notes && git add -A && git commit -m "inbox: ${TITLE}" && git push
