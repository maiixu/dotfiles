## Shared Skills 规则

调用任何 `{prefix}_*` skill 时，若存在 `{prefix}_shared` skill，先读取它再执行。

## Git 工作流

每次对任何项目做了确定的改动后，询问用户是否要 git commit + push：
> 要同步到远端吗？（git commit + push）

用户确认后再执行。不要自动 commit，不要跳过询问。

## 沟通偏好

解释技术问题时用第一性原理和底层实现，而非高层描述。
例如：不说「scope 是 git repo」，而说「Claude 运行 `git rev-parse --show-toplevel` 找到根目录并以此路径作为 key」。

## ⚠️ 事故：2026-03-07 主目录误删

`run_in_background=true` 的后台 shell 路径解析与交互式 shell 不同——`rm -rf ~/Local` 实际作用于 `~/`，永久删除了主目录大量文件，包括无备份的 `~/archive/20221206_白纸运动`。

**禁止事项：**
- 禁止在 `run_in_background=true` 下执行任何破坏性操作
- 破坏性命令执行前必须确认路径已正确展开
- 优先用 `trash` 而非 `rm -rf`

---

# ⚠️ REMINDER: Chinese and English output ONLY. No Korean. No Japanese. No exceptions.
