---
name: step-through
description: One-at-a-time decision TUI. Present a list of proposed actions to the user interactively — one item at a time, with number-key shortcuts. User can accept, edit, refine via prompt (Claude rephrases inline), change routing, or skip. Returns confirmed decisions as JSON.
---

Present the decisions using the step-through TUI:

## Input format

Serialize decisions as a JSON array written to a temp file:

```json
[
  {
    "uuid":           "item-uuid",
    "original_title": "raw inbox text as-is",
    "title":          "🔎 Proposed rephrased action title",
    "project":        "Project Name",
    "when":           "anytime",
    "deadline":       null,
    "notes":          "optional context shown to user"
  }
]
```

## Invocation

```bash
python3 ~/.claude/skills/step-through/step-through.py \
  --input /tmp/step-through-in.json \
  --output /tmp/step-through-out.json
```

## Output

Same array with `"action": "accept" | "skip"` added to each item.
Title, project, when, deadline may have been modified by the user.

**Only act on items where `action == "accept"`. Items with `action == "skip"` stay untouched.**

## Notes

- Requires `AWS_PROFILE=bedrock-claude` in environment (used for inline title refinement)
- Must be run in a terminal (not background) — it is an interactive TUI
