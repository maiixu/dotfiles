#!/bin/bash
# Block dangerous deletion commands before they execute.
# Exit 2 = block the action; Claude receives the stderr message as feedback.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block any attempt to bypass the rm→trash alias (e.g. /bin/rm, command rm, \rm, env rm)
if echo "$COMMAND" | grep -qE '(/bin/rm|/usr/bin/rm|\bcommand\s+rm\b|\\rm\b|\benv\s+rm\b|\bbuiltin\s+rm\b|\brmf\b)'; then
  echo "BLOCKED: Direct rm binary or alias bypass detected. Use 'trash' for safe deletion." >&2
  exit 2
fi

# Block rm -rf on home directory or its direct children
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*)\s+(~\/?\s*$|~/[^/]+\s*$|/Users/[^/]+\s*$|/Users/[^/]+/[^/]+\s*$)'; then
  echo "BLOCKED: rm -rf on home directory or direct child. Per CLAUDE.md safety rules, this operation is not allowed. Use 'trash' for safe deletion or target a more specific path." >&2
  exit 2
fi

# Block run_in_background combined with any rm/rmdir/mv variant
if echo "$INPUT" | jq -e '.run_in_background == true' > /dev/null 2>&1; then
  if echo "$COMMAND" | grep -qE '\brm\b|\brmdir\b'; then
    echo "BLOCKED: Deletion commands must not use run_in_background=true. Per CLAUDE.md safety rules, background shell path resolution can differ from interactive shell." >&2
    exit 2
  fi
fi

# Block rm -rf ~/archive (precious personal archive)
if echo "$COMMAND" | grep -qE 'rm\s+.*~/archive'; then
  echo "BLOCKED: ~/archive is protected. Per CLAUDE.md, this directory contains precious personal records and must not be deleted without explicit item-by-item confirmation." >&2
  exit 2
fi

exit 0
