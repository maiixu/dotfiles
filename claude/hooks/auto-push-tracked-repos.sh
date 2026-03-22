#!/usr/bin/env bash
# Auto-commit and push when Claude edits files in tracked repos (dotfiles, notes)
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null || echo "")

[ -z "$FILE_PATH" ] && exit 0
FILE_PATH="${FILE_PATH/#\~/$HOME}"

if [[ "$FILE_PATH" == "$HOME/code/dotfiles/"* ]] || [[ "$FILE_PATH" == "$HOME/.claude/"* ]]; then
  REPO="$HOME/code/dotfiles"
elif [[ "$FILE_PATH" == "$HOME/notes/"* ]]; then
  REPO="$HOME/notes"
else
  exit 0
fi

cd "$REPO"
git add -A
git diff --cached --quiet && exit 0

RELATIVE="${FILE_PATH#$REPO/}"
git commit -m "sync: edit $RELATIVE"
git push
