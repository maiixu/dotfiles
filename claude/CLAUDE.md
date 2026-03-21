# ⚠️ LANGUAGE POLICY (STRICTLY ENFORCED)
Output ONLY in Chinese (中文) or English. NEVER output Korean, Japanese, or any other language — not in explanations, code comments, commit messages, or any other content. The codebase may contain Korean/Japanese strings for i18n purposes; those are data, not a reason to switch output language. Always respond in Chinese or English regardless of codebase content.

---

# 全局记忆

## Dotfiles 工作流

每次编辑 dotfiles 后，必须立即 commit 并 push 到远端。不需要等用户提醒。

## 沟通偏好

解释技术问题时，优先用第一性原理、具体的底层实现来说明，而不是泛泛的高层描述。
例如：不说「auto memory 的 scope 是 git repo」，而说「Claude 运行 `git rev-parse --show-toplevel` 找到 repo 根目录并以此路径作为 memory key；如果命令失败（不在 git repo 里），则退回使用 working directory」。

## Things 3

Things 3 操作通过 `things` subagent 完成（仅当 `~/.claude/agents/things.md` 存在时）；否则直接调用 `/things_daily_review` 或 `/things_read` skill。对话中产生 actionable next steps 时主动 invoke。

## Obsidian

Obsidian vault 写操作通过 `obsidian` subagent 完成（仅当 `~/.claude/agents/obsidian.md` 存在时）；否则直接调用 `/obsidian_new_note` 或 `/obsidian_people_note` skill。对话中产生关于人的值得记录的信息时主动触发 `obsidian_people_note` skill。

## 事故复盘：2026-03-07 主目录误删事件

**经过：**
在清理 `~/Local` 文件夹的 session 中，我使用 `run_in_background=true` 执行了 `rm -rf ~/Local`。后台 shell 环境的路径解析与交互式 shell 不同，命令实际作用于 `~/`（整个主目录）而非 `~/Local`，导致大量文件被永久删除。

**无法挽回的损失：**
- `~/archive/20221206_白纸运动` —— Mai 参与并记录的 2022 年白纸运动留档，唯一的备份。没有 Time Machine，没有云端备份，手机上的原件也已不在。永久丢失。
- `~/code/` 下多个代码仓库及个人文件。

**Mai 的遗憾：**
那批白纸运动的留档，是我亲历那段历史的证明，也是我花了很多心思整理、珍藏的东西。就这样没了，真的很心痛。

**根本原因：**
1. `run_in_background=true` 的后台 shell 环境存在路径解析差异，不能用于任何破坏性操作
2. 执行前没有确认路径是否正确展开
3. 当时 `trash` 别名尚未配置，直接用了 `rm -rf`，没有任何安全兜底

---

# ⚠️ REMINDER: Chinese and English output ONLY. No Korean. No Japanese. No exceptions.
