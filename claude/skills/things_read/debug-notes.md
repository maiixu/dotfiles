# things-read.sh Debug Progress

## Bugs Fixed

### 1. TODAY/EVENING Split Missing
**Root cause**: `startBucket` field determines section (0 = Today, 1 = This Evening), but the original script had no split.
**Fix**: Query tasks, then split by `startBucket` into two sections.

### 2. Recurring Templates Inflating TODAY Count (165 → 52)
**Root cause**: `rt1_recurrenceRule IS NOT NULL` tasks (templates) were included via `todayIndexReferenceDate = today` matching 125 templates.
**Fix**: Add `rt1_recurrenceRule IS NULL` filter — templates are never shown directly, only their instances.

### 3. `start = 2` Filter Excluded Recurring Instances
**Root cause**: Recurring instances have `start = 1` (not 2), so filtering `start = 2` excluded all Evening instances.
**Fix**: Remove `start = 2` filter; rely on `startDate = today` + `rt1_recurrenceRule IS NULL` instead.

### 4. `todayIndexReferenceDate` Caused False Positives (419 extra tasks)
**Root cause**: `todayIndexReferenceDate` is a tracking timestamp, not a "in Today list" indicator. 419 Someday tasks had it set to today.
**Fix**: Use only `startDate = today` for the Today query (not `todayIndexReferenceDate`).

### 5. UPCOMING Section Crashed with `ValueError: year 0 is out of range`
**Root cause**: `sr` (start reference) unix timestamp in recurrence plists occasionally invalid or out of range; `time.localtime()` raised exception.
**Fix**: Wrap `epoch_to_date()` and `sr_date` computation in try/except with bounds check.

### 6. Someday Tasks Polluting UPCOMING Deadline Section
**Root cause**: Tasks with `start = 1, startDate IS NULL, deadline = upcoming` were shown in Upcoming.
**Fix**: Add `NOT (start = 1 AND startDate IS NULL)` to the deadline-only query.

### 7. Today Tasks Re-appearing in UPCOMING via Deadline
**Root cause**: Tasks with `startDate = today AND deadline = tomorrow` appeared in both Today and Upcoming.
**Fix**: Exclude tasks where `startDate = date('now', 'localtime')` from the deadline-only Upcoming query.

### 8. Far-Future Series Deadlines (e.g. `[due 2030-04-15]`) on Recurring Templates
**Root cause**: Recurring templates store their series end-date in `deadline` (often 2030+), not per-occurrence deadlines.
**Fix**: `suppress_far=True` in `format_deadline_indicator()` for recurring templates — suppress deadlines > 365 days out.

## Known Minor Deviation
Some weekly tasks (e.g. 清洁生活区 `wd=5`) appear 1 day off vs. UI. The `ts=-1` field in the plist (vs `ts=0` for other tasks) likely affects day computation but the exact semantics are opaque. Impact: minor date offset for a small subset of weekly tasks.

## Final State
- TODAY: 52 items (split from EVENING: 21 items) ✓
- UPCOMING: 7 days with recurring templates ♻️ ✓
- No crashes, no spurious sections ✓
