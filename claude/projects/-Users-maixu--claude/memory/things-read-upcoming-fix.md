# things-read.sh Upcoming View Fix Plan

## Status: NOT STARTED

## File
`~/code/dotfiles/claude/scripts/things/things-read.sh` (lines 207-376, Python UPCOMING section)

## Reference PDF
`~/inbox/Print Document for "Upcoming".pdf` (25 pages, Things 3 UI snapshot from 2026-03-09)

## Problems

### 1. Missing recurrence types
- `fu=8` (monthly): 36 templates, completely unimplemented
  - `{dy: N}` format: day-of-month (0-indexed, -1=last day)
  - `{wdo: W, wd: D}` format: Nth weekday of month (wd: 0=Sun..6=Sat, wdo=-1=last)
  - `fa` = every N months; check `months_elapsed % fa == 0`
- `fu=4` (yearly): 14 templates, completely unimplemented
  - `{dy: D, mo: M}` format: mo is 0-indexed month, dy is 0-indexed day (-1=last)
- `ts` field (time shift in days): templates like `季度大扫除 ts=-7`, `Free Birthday Bowl ts=-30` appear early

### 2. Scope too limited
- Script: 7 individual days + "UPCOMING DEADLINES (30 days)"
- Things 3: individual days (7) → rest of month → months → years → "Repeating To-Dos"

### 3. tp=1 templates (after completion) mishandled
- `tp` is in the recurrence rule plist blob, NOT a TMTask column
- 3 templates: Auto Maintenance (fu=8,fa=6), 剪头 (fu=16,fa=60), Buy Uber Gift Card (fu=16,fa=14)
- Should go in "Repeating To-Dos" section at end, NOT in date slots

### 4. Ordering
- Things 3 Upcoming view ordering is NOT in the database
- No column (`index`, `todayIndex`, `creationDate`, `rowid`, heading index) matches PDF order
- Best heuristic: `(heading_index, task_index, creationDate)` — imperfect but reasonable
- Requires manual verification against PDF

## Implementation Steps

1. Implement `fu=8` monthly in `template_fires_on()`
2. Implement `fu=4` yearly in `template_fires_on()`
3. Handle `ts` (time shift) offset in fire date calculation
4. Split templates by `tp` field (0=fixed schedule, 1=after completion)
5. Bulk-fetch all future scheduled + deadline tasks (instead of per-day SQL)
6. Bulk-fetch existing recurring instances for dedup
7. Extend date range: 7 individual days → rest of month → months → years
8. Merge scheduled + deadline + recurring into single sorted list per period
9. Remove "UPCOMING DEADLINES" section (doesn't exist in Things 3)
10. Add "Repeating To-Dos" section at end
11. Add `ORDER BY t."index"` to recurring templates query (line 218)

## Verification
1. Run script, compare output against PDF section by section
2. Check: date grouping headers match (Tomorrow, Wed..Mon, March 17-31, April..July, 2026, 2027, Repeating To-Dos)
3. Check: every task in PDF appears on correct date in output
4. Check: no extra tasks appear
5. Ordering will be approximate — iterate heuristic as needed

## Key DB Facts
- Things 3 DB: `~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/main.sqlite`
- 132 active recurring templates total
- ALL templates have `project=NULL`, organized under headings (type=2) with no area
- Epoch derived dynamically: `CAST(userModificationDate AS INTEGER) - startDate`
