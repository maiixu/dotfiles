---
name: obsidian-people
description: Use when recording a memory about a person.
---

deps:    obsidian-shared

params:
  name    required   $ARGUMENTS
  memory  required   $ARGUMENTS

```
$ARGUMENTS: "{name} {memory}"
              ↓
        grep People tag → match filename by name
              ↓
   1 match → show note title → y/n confirm
   0 or 2+ matches → numbered options → wait
              ↓
   memory obvious? → preview at top → y/n confirm
   memory ambiguous? → numbered options → wait → preview → confirm
              ↓
        insert / create → git commit + push
```

## Step 1 — Find existing note

```bash
grep -rl "Meta--元数据/Type--类型/People--人际" ~/notes --include="*.md"
```

Match filenames against the person's name. Then via AskUserQuestion:

- **1 match**: "找到 {Name}，确认更新？`y` 继续"
- **0 matches**: "没找到，新建 {Name} 的 note？`y` 继续，或输入正确名字"
- **2+ matches**: 列出选项 `1. {name1}  2. {name2}  3. 新建`

Wait for confirmation before proceeding.

## Step 2 — Preview before write

Draft options for how to write the memory line, then ask via AskUserQuestion. Show as many as make sense (1–5); always end with 自定义:

```
记忆选项：
1. 20260328 {as-is，原话}
2. 20260328 {polished，口语转书面，更简洁}
3. 20260328 {merged，多点合一行}（多个点时）
4. 自定义 →
```

最后一项永远是「自定义 →」，编号跟着实际选项数走。

If the input is already clean and one version is obvious best, skip the options and just show that one with `y` to confirm.

Wait for selection. Apply edits if `4.自定义` or further feedback given.

## Step 3 — Update or create

### If note exists — insert at the top of the memory section

New entry goes after the opening description (first non-blank line after H2), before any existing memories:

```
{H2 + description}

YYYYMMDD {new memory}

{existing memories...}

---
```

### If note does not exist — create new

Get timestamp:
```bash
date +"%Y%m%d%H%M"
```

Determine destination folder from current date (see `obsidian-shared` for Journal structure).

```
## {Name}

YYYYMMDD {memory content}

---
{timestamp}

#Meta--元数据/Type--类型/People--人际
```

## Step 4 — Commit, push, report

```bash
cd ~/notes && git add -A && git commit -m "people: {Name}" && git push
```

Report: updated vs created, what was recorded.
