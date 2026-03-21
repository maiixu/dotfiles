---
name: hotkey-doctor
description: Use when auditing hotkey config across Aerospace and Karabiner.
context: fork
---

Audit the user's hotkey configuration across Aerospace (window manager) and Karabiner (text operations), compare against the reference table, and flag inconsistencies.

## Config file paths

- Aerospace: `~/code/dotfiles/aerospace/aerospace.toml`
- Karabiner: `~/code/dotfiles/karabiner/karabiner.json`

## Steps

1. Read both config files.
2. Parse all bindings and render a unified table (columns: key | `rctrl` | `rctrl+shift` | `alt` | `alt+shift` | `alt+ctrl` | `alt+ctrl+shift`).
3. Compare against the reference table below. For each discrepancy, note: key, expected value, actual value, and whether it's a known pending change or a real drift.
4. Flag any mental model inconsistencies: same key letter with semantically unrelated meanings across the `rctrl` and `alt` layers.

## Reference table (last audited: 2026-03-21)

> Note: The `i/o` row reflects the **proposed** state (i=字符左, o=字符右). The actual karabiner.json still maps `u/i` for char nav and `o` for new-line-below. This is a known pending change — flag it as "pending update" rather than drift.

| 键 | `rctrl` | `rctrl+shift` | `alt` | `alt+shift` | `alt+ctrl` | `alt+ctrl+shift` |
|---|---|---|---|---|---|---|
| `h` | 词左 ⌥← | 选择词左 | 聚焦左 | 移动窗口左 | 聚焦上一显示器 | 移动窗口到上一显示器 |
| `j` | 行下 ↓ | 选择行下 | 聚焦下 | 移动窗口下 | 下一 workspace | 移动窗口到下一 workspace |
| `k` | 行上 ↑ | 选择行上 | 聚焦上 | 移动窗口上 | 上一 workspace | 移动窗口到上一 workspace |
| `l` | 词右 ⌥→ | 选择词右 | 聚焦右 | 移动窗口右 | 聚焦下一显示器 | 移动窗口到下一显示器 |
| `u` | 下方新行 | — | — | — | — | — |
| `i` | 字符左 ← | 选择字符左 | 垂直布局切换 | join-with left | — | — |
| `o` | 字符右 → | 选择字符右 | 水平布局切换 | join-with right | — | — |
| `n` | 文档顶部 | 选到文档顶部 | — | — | — | — |
| `m` | 文档底部 | 选到文档底部 | — | — | — | — |
| `[` | 行首 | 选到行首 | — | — | — | — |
| `]` | 行尾 | 选到行尾 | — | — | — | — |
| `p` | 删除词 ⌥⌫ | 删除整行 ⌘⌫ | back-and-forth | — | — | — |
| `y` | 复制当前行 | — | — | — | — | — |
| `;` | Escape | — | balance-sizes | flatten-tree | — | — |
| `1`–`9` | — | — | 切换 workspace | 移动窗口到 workspace | — | — |
| `0` | — | — | workspace 10 (内置屏) | 移动窗口到 10 | — | — |
| `-` | — | — | 缩小 -50 | — | — | — |
| `=` | — | — | 扩大 +50 | — | — | — |

## Known pending changes

None.
