#!/bin/bash
# Update tasks in Things 3 via URL scheme.
# Reads a JSON array from stdin.
#
# Input format:
#   [
#     {
#       "id": "TASK_UUID",
#       "title": "New title",       (optional)
#       "list": "Project Name",     (optional, project or area title)
#       "when": "anytime",          (optional: today|anytime|someday|YYYY-MM-DD)
#       "deadline": "2026-03-15"    (optional, YYYY-MM-DD or null to clear)
#     },
#     ...
#   ]

if [ -z "$THINGS_TOKEN" ]; then
  echo "ERROR: THINGS_TOKEN not set" >&2
  exit 1
fi

DATA=$(cat)

if [ -z "$DATA" ] || [ "$DATA" = "[]" ]; then
  echo "No items to update."
  exit 0
fi

RESULT=$(python3 - "$DATA" "$THINGS_TOKEN" <<'EOF'
import sys, json, urllib.parse, subprocess

items = json.loads(sys.argv[1])
token = sys.argv[2]

ops = []
for item in items:
    attrs = {}
    for key in ["title", "list", "when", "deadline", "notes"]:
        if key in item:
            attrs[key] = item[key]
    ops.append({"type": "update", "id": item["id"], "attributes": attrs})

encoded = urllib.parse.quote(json.dumps(ops))
url = f"things:///json?data={encoded}&auth-token={token}"
subprocess.run(["open", url])
print(f"Updated {len(ops)} item(s).")
EOF
)

echo "$RESULT"
