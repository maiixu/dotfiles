#!/bin/bash
# Detect Korean/Japanese in last assistant message.
# Exit 2 → Claude re-answers immediately in Chinese.

INPUT=$(cat)

# Prevent infinite re-trigger loop
if echo "$INPUT" | jq -e '.stop_hook_active == true' > /dev/null 2>&1; then
  exit 0
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Extract text from last assistant message in transcript
LAST_TEXT=$(python3 - "$TRANSCRIPT" <<'PYEOF'
import sys, json
path = sys.argv[1]
last_text = ""
with open(path) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            if obj.get("role") == "assistant" or obj.get("type") == "assistant":
                content = obj.get("content", "")
                if isinstance(content, str):
                    last_text = content
                elif isinstance(content, list):
                    parts = []
                    for block in content:
                        if isinstance(block, dict):
                            parts.append(block.get("text", ""))
                    last_text = " ".join(parts)
        except json.JSONDecodeError:
            continue
print(last_text)
PYEOF
)

if [ -z "$LAST_TEXT" ]; then
  exit 0
fi

# Check for Korean (Hangul) or Japanese (Hiragana/Katakana)
HAS_BAD=$(python3 -c "
import sys
text = sys.stdin.read()
for ch in text:
    cp = ord(ch)
    if (0xAC00 <= cp <= 0xD7AF or  # Hangul syllables
        0x1100 <= cp <= 0x11FF or  # Hangul Jamo
        0x3130 <= cp <= 0x318F or  # Hangul compatibility Jamo
        0x3040 <= cp <= 0x309F or  # Hiragana
        0x30A0 <= cp <= 0x30FF):   # Katakana
        print('yes')
        sys.exit(0)
print('no')
" <<< "$LAST_TEXT")

if [ "$HAS_BAD" = "yes" ]; then
  echo "Output contains Korean or Japanese. Re-answer the previous question immediately in Chinese (中文) only. No Korean, no Japanese, no exceptions."
  exit 2
fi

exit 0
