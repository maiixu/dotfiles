---
name: dotfiles_hotkey_doctor
description: Use when auditing hotkey config across Aerospace and Karabiner.
context: fork
---

Audit the user's hotkey configuration across Aerospace (window manager) and Karabiner (text operations). The actual config files are the source of truth — read them first, then update the reference table below to reflect current reality, then flag any issues.

## Config file paths

- Aerospace: `~/code/dotfiles/aerospace/aerospace.toml`
- Karabiner: `~/code/dotfiles/karabiner/karabiner.json`

## Steps

1. Read both config files in full.
2. Parse all bindings across every modifier combination (rctrl, rctrl+shift, alt, alt+shift, alt+ctrl, alt+ctrl+shift).
3. Render a unified table from the actual config (columns: key | `rctrl` | `rctrl+shift` | `alt` | `alt+shift` | `alt+ctrl` | `alt+ctrl+shift`). Every row and column must be filled from the config, not inferred from the reference table.
4. Compare the rendered table against the reference table below. For each cell that differs, note: key, modifier, reference value, actual value.
5. Update the reference table in this file to match the actual config. Update the "last audited" date.
6. Flag any mental model inconsistencies: same key letter with semantically unrelated meanings across the `rctrl` and `alt` layers.

## Reference table (last audited: 2026-03-22)

| 键 | `rctrl` | `rctrl+shift` | `alt` | `alt+shift` | `alt+ctrl` | `alt+ctrl+shift` |
|---|---|---|---|---|---|---|
| `h` | 词左 ⌥← | 选择词左 | 聚焦左 | 移动窗口左 | 聚焦上一显示器 | 移动窗口到上一显示器 |
| `j` | 行下 ↓ | 选择行下 | 聚焦下 | 移动窗口下 | 下一 workspace | 移动窗口到下一 workspace |
| `k` | 行上 ↑ | 选择行上 | 聚焦上 | 移动窗口上 | 上一 workspace | 移动窗口到上一 workspace |
| `l` | 词右 ⌥→ | 选择词右 | 聚焦右 | 移动窗口右 | 聚焦下一显示器 | 移动窗口到下一显示器 |
| `u` | 下方新行 (vim o) | 上方新行 (vim O) | — | — | — | — |
| `i` | 字符左 ← | 选择字符左 | 垂直布局切换 | join-with left | — | — |
| `o` | 字符右 → | 选择字符右 | 水平布局切换 | join-with right | — | — |
| `n` | 文档顶部 fn↑ | 选到文档顶部 | — | — | — | — |
| `m` | 文档底部 fn↓ | 选到文档底部 | — | — | — | — |
| `[` | 行首 | 选到行首 | — | — | — | — |
| `]` | 行尾 | 选到行尾 | — | — | — | — |
| `p` | 删除词 ⌥⌫ | 删除整行 ⌘⌫ | back-and-forth | — | — | — |
| `y` | 复制当前行 | — | — | — | — | — |
| `;` | Escape | — | balance-sizes | flatten-workspace-tree | — | — |
| `1`–`9` | — | — | 切换 workspace | 移动窗口到 workspace | — | — |
| `0` | — | — | workspace 10 (内置屏) | 移动窗口到 10 | — | — |
| `-` | — | — | 缩小 -50 | — | — | — |
| `=` | — | — | 扩大 +50 | — | — | — |

## Known pending changes

None.
