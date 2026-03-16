---
name: rss-digest-project
description: Core context for the RSS Digest project — what it is, current state, and what's next
type: project
---

Personal daily information filter. Replaces manual RSS browsing with an AI-curated terminal digest.

**Why:** Run manually each morning; takes ~20s; outputs numbered list with interactive link opener.

**Current state (2026-03-15):**
- `digest.py` + `feeds.json` + `twitter_fetch.py` all working standalone
- Twitter fetch is NOT yet wired into `digest.py` (next step)
- Weekly digest script not yet built
- No cron/scheduling yet — run manually

**How to apply:** When suggesting new features or changes, prioritize completing the Twitter→digest integration before new categories or delivery mechanisms.
