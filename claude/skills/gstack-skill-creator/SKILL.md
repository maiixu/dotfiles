---
name: gstack-skill-creator
description: Use when importing a gstack skill into dotfiles.
---

Import a skill from `~/code/gstack` into dotfiles as a tracked `gstack_*` skill.

## Params

- `$ARGUMENTS` — gstack skill name in any case (e.g. `plan-eng-review`, `plan_eng_review`, `planEngReview`); if not provided, list available gstack skills and ask

## Steps

### 1. Resolve skill name

Normalize `$ARGUMENTS` to kebab-case gstack dir name and underscore-case dotfiles name:
- gstack dir: `~/code/gstack/<kebab-name>/`
- dotfiles target: `~/code/dotfiles/claude/skills/gstack_<snake_name>/SKILL.md`

If `$ARGUMENTS` not provided:
```bash
ls ~/code/gstack/ | grep -v '^\.' | sort
```
Ask user which skill to import.

### 2. Verify source exists

```bash
ls ~/code/gstack/<kebab-name>/SKILL.md
```

Abort if not found.

### 3. Check not already imported

```bash
ls ~/code/dotfiles/claude/skills/ | grep gstack_
```

If target dir already exists, show current description and ask user to confirm overwrite.

### 4. Copy and fix

```bash
mkdir -p ~/code/dotfiles/claude/skills/gstack_<snake_name>
cp ~/code/gstack/<kebab-name>/SKILL.md ~/code/dotfiles/claude/skills/gstack_<snake_name>/SKILL.md
```

Then apply these edits to the copied file:
- Replace all `~/.claude/skills/gstack` → `~/code/gstack`
- Set `name:` field to `gstack_<snake_name>`

### 5. Commit and push

```bash
cd ~/code/dotfiles
git add claude/skills/gstack_<snake_name>/
git commit -m "skills: import gstack/<kebab-name> as gstack_<snake_name>"
git push
```

### 6. Confirm

Tell user: `gstack_<snake_name>` is now available as `/<snake_name>`.
