---
name: things_shared
description: Things 3 shared reference — areas, routing, scheduling, write API.
---

Shared reference for all `things_*` skills. Loaded automatically before any `things_*` operation.

## Areas & Projects

| Area | Projects |
|------|----------|
| 🤘 自我 Self | 💭 问题 Questions, ☑️ 任务 Tasks, 🗓️ 事件 Events, 🧠 效率 Productivity, 🚗 杂务 Chores, 🐈 猫猫 Cat |
| 🚀 项目 Projects | 🍵 茶艺 Tea Brewing |
| 💰 财务 Personal Finance | 🏦 现金流 Cash Flow, 💳 消费 Expense, 📈 投资 Investment |
| 💪 身体 Body | 🍱 饮食 Meal, 🏋️‍♂️ 训练 Training, 💊 护理 Care |
| 🚧 投入 Commitments | 📚 阅读 Read, ✍️ 写作 Write, 💻 技术 Tech, 🎹 音乐 Music, 📷 摄影 Photography, 🎥 电影 Movies, 🎮 游戏 Games, 🥰 家庭 Family, 🙌 人际 Friends |

## Emoji Conventions

**Action:** 🔎 Research · 🔍 Deep strategy research · 💻 Tech · 📱 Mobile · 📞 Phone call · 💬 Waiting for reply · 🏗️ Ongoing build · 💭 Blog/essay idea · ✅ Daily routine

**Content:** 🥚 Meal · 🍅 Pomodoro routine · 📖 Book · 🎸 Guitar · 🍿 Movie/TV · 🗓️ Event/trip

**Financial:** 🌟 Credit card reward · 💰 Money transfer · 💳 Purchase

**Status:** 🔴 Blocked (tag) · [Blocked by X] (inline in title)

## Tagging Conventions

**Duration:** `5m` `10m` `15m` `30m` `45m` `1h` `1h15m` `1h30m` `1h45m` `2h` `4h` `8h`

**Energy:** `🔋 High Voltage` · `🪫 Low Voltage` · `⚡️ Energy`

**Time of day:** `🪥 Morning` · `🧴 Evening`

**Recurring:** `Daily` `Weekly` `Biweekly` `Monthly` `Quarterly` `Yearly` `Every Three Weeks` etc.

**Other:** `🛒 Errands` · `📖 Reading List` · `📝 Template` · `⏰ Estimated` · `🌟 Starred` · `On Demand`

## Routing Guide

| Task type | Project |
|-----------|---------|
| Research question, life philosophy | 🤘 Self / 💭 问题 Questions |
| One-off personal to-do | 🤘 Self / ☑️ 任务 Tasks |
| Trips, events, concerts | 🤘 Self / 🗓️ 事件 Events |
| Productivity/tool setup | 🤘 Self / 🧠 效率 Productivity |
| Household chores, errands | 🤘 Self / 🚗 杂务 Chores |
| Cat care | 🤘 Self / 🐈 猫猫 Cat |
| Banking, cash flow, checking bonuses | 💰 Finance / 🏦 现金流 Cash Flow |
| Credit card perks, subscriptions, purchases | 💰 Finance / 💳 消费 Expense |
| Investments, research stocks/crypto | 💰 Finance / 📈 投资 Investment |
| Diet, nutrition, meal research | 💪 Body / 🍱 饮食 Meal |
| Workouts, training plans | 💪 Body / 🏋️‍♂️ 训练 Training |
| Health, skincare, sleep, supplements | 💪 Body / 💊 护理 Care |
| Books, articles, feeds, podcasts | 🚧 Commitments / 📚 阅读 Read |
| Blog posts, Anki cards, writing | 🚧 Commitments / ✍️ 写作 Write |
| Work tech, system design, side projects | 🚧 Commitments / 💻 技术 Tech |
| Guitar, music theory, concerts | 🚧 Commitments / 🎹 音乐 Music |
| Photography, photo management, editing | 🚧 Commitments / 📷 摄影 Photography |
| Movies, TV shows, reviews | 🚧 Commitments / 🎥 电影 Movies |
| Games | 🚧 Commitments / 🎮 游戏 Games |
| Family | 🚧 Commitments / 🥰 家庭 Family |
| Friends, social, gifts | 🚧 Commitments / 🙌 人际 Friends |

**When in doubt → Inbox, when=anytime.** Daily review handles triage.

- Quick research: prefix 🔎, route to relevant project
- Investment research: `🔎 投资标的：[ticker]` → 📈 投资 Investment
- Writing ideas: prefix 💭 → ✍️ 写作 Write
- Never add duration/energy tags unless explicitly requested
- Recurring task templates have a sentinel deadline (~2030); ignore for scheduling

## Scheduling Philosophy

**Week structure: Saturday → Friday**

| Anchor | Deadline |
|--------|----------|
| End of week | coming Friday |
| End of month | last Friday of the month |
| End of quarter | last Friday of the quarter |
| End of year | last Friday of December |

Exception: real hard dates (tax deadlines, event dates) use the actual date.

**Weekend-only tasks** (large time blocks, errands, deep-focus): use Sunday of target week.

**`when` vs `deadline`:**
- `when` = when task appears in timeline. Use `anytime` for almost everything.
- `deadline` = completion due date (shown in red). Use for EOW/EOM/EOQ/EOY and hard dates.
- **NEVER use `when` for Friday anchors** — always use `deadline`.

Valid `when`: `today` `tomorrow` `evening` `anytime` `someday` `yyyy-mm-dd`
Valid `deadline`: `yyyy-mm-dd`

**Deadline is required for almost every task.** Default to EOW. Omit only if genuinely open-ended.

## Writing to Things

**Auth token** — from env: `$THINGS_TOKEN` (set in `~/.claude/settings.local.json`)

**Single new task (no auth token needed):**
```bash
python3 -c "
import urllib.parse, subprocess
params = urllib.parse.urlencode({
    'title': 'Task title',
    'notes': 'Optional notes',
    'list': 'Inbox',
    'when': 'anytime',
    'deadline': 'YYYY-MM-DD',
    'tags': 'tag1,tag2',
})
subprocess.run(['open', f'things:///add?{params}'])
"
```

**Update existing tasks (requires auth token):**
```bash
echo '[{"id":"UUID","title":"New title","list":"Project","when":"anytime","deadline":"YYYY-MM-DD"}]' \
  | bash ~/code/things-scripts/things-write.sh
```

`list`: exact project or area title, or `Inbox`
`tags`: comma-separated, must match exactly (copy from `things_read` output)
