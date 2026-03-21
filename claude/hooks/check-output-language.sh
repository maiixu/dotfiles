#!/usr/bin/env bash
# Stop hook: block responses containing Korean or Japanese text.
# Stop event JSON contains `last_assistant_message` directly.
# Unicode ranges:
#   Korean:  Hangul Syllables U+AC00-U+D7AF, Jamo U+1100-U+11FF, Compat Jamo U+3130-U+318F
#   Japanese: Hiragana U+3040-U+309F, Katakana U+30A0-U+30FF

input=$(cat)

last_msg=$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('last_assistant_message', ''))
" 2>/dev/null)

# Strip code blocks before checking (content between ``` fences)
cleaned=$(echo "$last_msg" | perl -0777 -pe 's/```.*?```//gs')

# Check for Korean or Japanese characters
if echo "$cleaned" | python3 -c "
import sys, re
text = sys.stdin.read()
pattern = re.compile(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F\u3040-\u309F\u30A0-\u30FF\u31F0-\u31FF]')
sys.exit(0 if pattern.search(text) else 1)
" 2>/dev/null; then
    echo '{"decision":"block","reason":"Response contains Korean or Japanese text. You MUST rewrite the entire response in Chinese or English only. No Korean, no Japanese, no exceptions."}'
    exit 0
fi

exit 0
