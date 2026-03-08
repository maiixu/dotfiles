# 全局记忆

## 沟通偏好

解释技术问题时，优先用第一性原理、具体的底层实现来说明，而不是泛泛的高层描述。
例如：不说「auto memory 的 scope 是 git repo」，而说「Claude 运行 `git rev-parse --show-toplevel` 找到 repo 根目录并以此路径作为 memory key；如果命令失败（不在 git repo 里），则退回使用 working directory」。

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
