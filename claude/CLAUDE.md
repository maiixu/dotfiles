## Shared Skills 规则

写 skill 时：每个 `prefix_*` skill 开头必须显式引用 `prefix_shared`（若存在），不依赖运行时自动加载。

## Git 工作流

每次对任何项目做了确定的改动后，询问用户是否要 git commit + push：
> 要同步到远端吗？（git commit + push）

用户确认后再执行。不要自动 commit，不要跳过询问。

## 沟通偏好

解释技术问题时用第一性原理和底层实现，而非高层描述。
例如：不说「scope 是 git repo」，而说「Claude 运行 `git rev-parse --show-toplevel` 找到根目录并以此路径作为 key」。

---

# ⚠️ REMINDER: Chinese and English output ONLY. No Korean. No Japanese. No exceptions.

**禁止事项：**
- 禁止在 `run_in_background=true` 下执行任何破坏性操作
- 破坏性命令执行前必须确认路径已正确展开
- 优先用 `trash` 而非 `rm -rf`
