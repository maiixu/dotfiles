#!/bin/bash
# Read-only overview of Things 3 database.
# Usage: ./read-things.sh [--full]
#   --full  Include all open tasks

DB=$(find ~/Library/Group\ Containers/JLMPQHK86H.com.culturedcode.ThingsMac \
  -name "main.sqlite" -not -path "*/Backups/*" 2>/dev/null | head -1)

if [ -z "$DB" ]; then
  echo "ERROR: Things 3 database not found" >&2
  exit 1
fi

q() { sqlite3 "$DB" "$1"; }

# Dynamically derive epoch offset from most recently modified task.
# Things 3 stores INTEGER dates (startDate, deadline) as seconds from
# a personalized epoch (the user's first sync date). We recover it via:
#   epoch = userModificationDate - startDate
# where both fields encode the same "now".
EPOCH=$(q "
  SELECT CAST(userModificationDate AS INTEGER) - startDate
  FROM TMTask
  WHERE startDate IS NOT NULL AND startDate > 0
    AND userModificationDate IS NOT NULL
  ORDER BY userModificationDate DESC LIMIT 1;")

if [ -z "$EPOCH" ]; then
  echo "ERROR: Could not derive Things date epoch" >&2
  exit 1
fi

echo "=============================="
echo "THINGS 3 OVERVIEW"
echo "Generated: $(date '+%Y-%m-%d %H:%M')"
echo "=============================="

echo ""
echo "## AREAS"
q "SELECT '  ' || title FROM TMArea ORDER BY 'index';"

echo ""
echo "## TAGS"
q "SELECT '  ' || title FROM TMTag ORDER BY 'index';"

echo ""
echo "## OPEN PROJECTS (by area)"
q "
SELECT
  COALESCE((SELECT title FROM TMArea WHERE uuid = t.area), '(No Area)') AS area_name,
  '  [project] ' || t.title
FROM TMTask t
WHERE t.type = 1 AND t.status = 0 AND t.trashed = 0
ORDER BY area_name, t.'index';"

echo ""
echo "## INBOX ($(q "SELECT count(*) FROM TMTask WHERE start=0 AND status=0 AND trashed=0 AND type=0") items)"
q "
SELECT '  ' ||
  CASE WHEN deadline IS NOT NULL
    THEN '[due ' || date(deadline + $EPOCH, 'unixepoch', 'localtime') || '] '
    ELSE ''
  END || title
FROM TMTask
WHERE start = 0 AND status = 0 AND trashed = 0 AND type = 0
ORDER BY 'index';"

echo ""
echo "## TODAY & UPCOMING (next 7 days)"
q "
SELECT
  date(t.startDate + $EPOCH, 'unixepoch', 'localtime') AS scheduled,
  COALESCE(
    (SELECT title FROM TMArea WHERE uuid = t.area),
    (SELECT a.title FROM TMArea a
     JOIN TMTask p ON p.area = a.uuid
     WHERE p.uuid = COALESCE(
       (SELECT project FROM TMTask WHERE uuid = t.heading), t.project)
     LIMIT 1),
    '—') AS area,
  COALESCE(
    (SELECT title FROM TMTask WHERE uuid = COALESCE(
      (SELECT project FROM TMTask WHERE uuid = t.heading), t.project)),
    '—') AS project,
  t.title ||
  CASE WHEN t.notes IS NOT NULL AND t.notes != ''
    THEN char(10) || '    ' || replace(substr(t.notes, 1, 120), char(10), ' | ')
    ELSE ''
  END
FROM TMTask t
WHERE t.status = 0 AND t.trashed = 0 AND t.type = 0
  AND t.startDate IS NOT NULL
  AND date(t.startDate + $EPOCH, 'unixepoch', 'localtime')
      BETWEEN date('now', 'localtime')
          AND date('now', '+7 days', 'localtime')
ORDER BY t.startDate;"

echo ""
echo "## UPCOMING DEADLINES (next 30 days)"
q "
SELECT
  '[due ' || date(t.deadline + $EPOCH, 'unixepoch', 'localtime') || '] ' ||
  COALESCE(
    (SELECT title FROM TMArea WHERE uuid = t.area),
    (SELECT a.title FROM TMArea a
     JOIN TMTask p ON p.area = a.uuid
     WHERE p.uuid = COALESCE(
       (SELECT project FROM TMTask WHERE uuid = t.heading), t.project)
     LIMIT 1),
    '—') || ' / ' ||
  COALESCE(
    (SELECT title FROM TMTask WHERE uuid = COALESCE(
      (SELECT project FROM TMTask WHERE uuid = t.heading), t.project)),
    '—') || ' | ' || t.title ||
  CASE WHEN t.notes IS NOT NULL AND t.notes != ''
    THEN char(10) || '    ' || replace(substr(t.notes, 1, 120), char(10), ' | ')
    ELSE ''
  END
FROM TMTask t
WHERE t.status = 0 AND t.trashed = 0
  AND t.deadline IS NOT NULL
  AND date(t.deadline + $EPOCH, 'unixepoch', 'localtime')
      BETWEEN date('now', 'localtime')
          AND date('now', '+30 days', 'localtime')
ORDER BY t.deadline;"

echo ""
echo "## STATS"
q "
SELECT 'Open tasks:    ' || count(*) FROM TMTask WHERE type=0 AND status=0 AND trashed=0
UNION ALL SELECT 'Open projects: ' || count(*) FROM TMTask WHERE type=1 AND status=0 AND trashed=0
UNION ALL SELECT 'Inbox:         ' || count(*) FROM TMTask WHERE start=0 AND status=0 AND trashed=0 AND type=0
UNION ALL SELECT 'Someday:       ' || count(*) FROM TMTask WHERE start=1 AND status=0 AND trashed=0 AND type=0
UNION ALL SELECT 'Anytime:       ' || count(*) FROM TMTask WHERE start=2 AND status=0 AND trashed=0 AND type=0;"

if [ "$1" = "--full" ]; then
  echo ""
  echo "## ALL OPEN TASKS (by area > project)"
  q "
  SELECT
    COALESCE(
      (SELECT a.title FROM TMTask p
       LEFT JOIN TMArea a ON a.uuid = p.area
       WHERE p.uuid = COALESCE(
         (SELECT project FROM TMTask WHERE uuid = t.heading),
         t.project)
       LIMIT 1),
      (SELECT title FROM TMArea WHERE uuid = t.area),
      '(No Area)'
    ) AS area_name,
    COALESCE(
      (SELECT title FROM TMTask WHERE uuid = COALESCE(
        (SELECT project FROM TMTask WHERE uuid = t.heading),
        t.project)),
      '(No Project)'
    ) AS project_name,
    CASE WHEN t.startDate IS NOT NULL
      THEN '[' || date(t.startDate + $EPOCH, 'unixepoch', 'localtime') || '] '
      ELSE ''
    END ||
    CASE WHEN t.deadline IS NOT NULL
      THEN '[due ' || date(t.deadline + $EPOCH, 'unixepoch', 'localtime') || '] '
      ELSE ''
    END || t.title AS task
  FROM TMTask t
  WHERE t.type = 0 AND t.status = 0 AND t.trashed = 0
  ORDER BY area_name, project_name, t.'index';"
fi
