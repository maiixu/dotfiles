#!/usr/bin/env python3
"""
sort-upcoming-day.py
Sort non-recurring tasks for a specific deadline date in Things 3 Upcoming view.

Sort order:
  1. 🔴 Blocked tag  → top
  2. 🌟 Starred tag  → second
  3. Area sidebar order (Projects → Self → Commitments → Body → Finance)
  4. Project index within area

Recurring tasks (↺) are never moved.

Usage:
  python3 sort-upcoming-day.py            # targets next Friday
  python3 sort-upcoming-day.py 2026-03-14 # specific date
  python3 sort-upcoming-day.py --dry-run  # preview without applying
"""

import sqlite3
import subprocess
import sys
import glob as glob_module
import os
from datetime import date, timedelta

# ── Database ──────────────────────────────────────────────────────────────────

def find_db():
    paths = glob_module.glob(os.path.expanduser(
        "~/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac"
        "/*/Things Database.thingsdatabase/main.sqlite"))
    if not paths:
        raise FileNotFoundError("Things 3 database not found")
    return paths[0]

def get_epoch(db):
    """Derive Things' integer date epoch: unix_ts = things_int + epoch."""
    conn = sqlite3.connect(db)
    row = conn.execute("""
        SELECT CAST(userModificationDate AS INTEGER) - startDate
        FROM TMTask
        WHERE startDate IS NOT NULL AND startDate > 0
          AND userModificationDate IS NOT NULL
        ORDER BY userModificationDate DESC LIMIT 1
    """).fetchone()
    conn.close()
    if not row:
        raise RuntimeError("Could not derive Things date epoch")
    return row[0]

# ── Date helpers ──────────────────────────────────────────────────────────────

def next_friday():
    today = date.today()
    days = (4 - today.weekday()) % 7
    if days == 0:
        days = 7
    return today + timedelta(days=days)

# ── Task queries ──────────────────────────────────────────────────────────────

def get_tasks_for_date(db, epoch, target_date):
    """
    Return all open to-dos with deadline on target_date.
    Columns: uuid, title, rt1_repeatingTemplate,
             area_index, project_index
    """
    conn = sqlite3.connect(db)
    rows = conn.execute(f"""
        SELECT
            t.uuid,
            t.title,
            t.rt1_repeatingTemplate,
            COALESCE(a_direct."index", a_via_proj."index", 999999) AS area_index,
            COALESCE(p."index", 999999)                            AS proj_index
        FROM TMTask t
        LEFT JOIN TMArea  a_direct  ON t.area    = a_direct.uuid
        LEFT JOIN TMTask  p         ON t.project  = p.uuid
        LEFT JOIN TMArea  a_via_proj ON p.area    = a_via_proj.uuid
        WHERE t.status  = 0
          AND t.trashed = 0
          AND t.type    = 0
          AND date(t.deadline + {epoch}, 'unixepoch', 'localtime')
              = date('{target_date.isoformat()}')
    """).fetchall()
    conn.close()
    return rows

def get_tags(db, uuid):
    conn = sqlite3.connect(db)
    tags = [r[0] for r in conn.execute("""
        SELECT tg.title FROM TMTag tg
        JOIN TMTaskTag tt ON tt.tag = tg.uuid
        WHERE tt.task = ?
    """, (uuid,)).fetchall()]
    conn.close()
    return tags

# ── AppleScript helpers ───────────────────────────────────────────────────────

def get_upcoming_ids():
    """Return current ordered list of all task IDs in Upcoming."""
    result = subprocess.run(['osascript', '-e', '''
        tell application "Things3"
            set out to {}
            repeat with td in to dos of list "Upcoming"
                set end of out to id of td
            end repeat
            return out
        end tell
    '''], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"AppleScript error: {result.stderr.strip()}")
    raw = result.stdout.strip()
    return [x.strip() for x in raw.split(', ') if x.strip()]

def apply_reorder(ordered_ids):
    ids_str = ','.join(ordered_ids)
    script = f'''
        tell application "Things3"
            _private_experimental_ reorder to dos in list "Upcoming" with ids "{ids_str}"
        end tell
    '''
    result = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"AppleScript error: {result.stderr.strip()}")

# ── Sort key ──────────────────────────────────────────────────────────────────

def sort_key(task, tags):
    _uuid, _title, _recurring, area_index, proj_index = task
    blocked = any('Blocked' in t for t in tags)
    starred = any('Starred' in t for t in tags)
    return (
        0 if blocked else 1,   # blocked first
        0 if starred else 1,   # starred second
        area_index,            # sidebar area order (lower = higher)
        proj_index,            # project order within area
    )

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    dry_run = '--dry-run' in sys.argv
    date_args = [a for a in sys.argv[1:] if not a.startswith('--')]

    target_date = date.fromisoformat(date_args[0]) if date_args else next_friday()
    print(f"Target date : {target_date}  {'(dry run)' if dry_run else ''}")

    db    = find_db()
    epoch = get_epoch(db)
    tasks = get_tasks_for_date(db, epoch, target_date)

    non_recurring = [t for t in tasks if t[2] is None]
    recurring     = [t for t in tasks if t[2] is not None]

    print(f"Non-recurring: {len(non_recurring)}  |  Recurring (frozen): {len(recurring)}")

    if not non_recurring:
        print("Nothing to sort.")
        return

    # Sort non-recurring
    task_tags = {t[0]: get_tags(db, t[0]) for t in non_recurring}
    sorted_nr = sorted(non_recurring, key=lambda t: sort_key(t, task_tags[t[0]]))

    print("\nNew order:")
    for t in sorted_nr:
        tags = task_tags[t[0]]
        flags = ' '.join(
            (['[BLOCKED]' if any('Blocked' in x for x in tags) else '']) +
            (['[STARRED]' if any('Starred' in x for x in tags) else ''])
        ).strip()
        print(f"  {flags:12s} {t[1][:60]}")
    print(f"  {'--- recurring ---':12s} ({len(recurring)} tasks, untouched)")

    if dry_run:
        print("\nDry run — nothing applied.")
        return

    # Fetch current Upcoming order and splice
    print("\nFetching Upcoming order from Things 3 …")
    upcoming = get_upcoming_ids()

    nr_ids  = {t[0] for t in non_recurring}
    rec_ids = {t[0] for t in recurring}
    day_ids = nr_ids | rec_ids

    positions = [i for i, uid in enumerate(upcoming) if uid in day_ids]
    if not positions:
        print("Target tasks not found in Upcoming — nothing to do.")
        return

    first, last = min(positions), max(positions)
    before = upcoming[:first]
    after  = upcoming[last + 1:]

    # Keep recurring in their original relative order within Upcoming
    rec_in_order = [uid for uid in upcoming if uid in rec_ids]

    new_order = before + [t[0] for t in sorted_nr] + rec_in_order + after

    print(f"Applying reorder ({len(new_order)} tasks total in Upcoming) …")
    apply_reorder(new_order)
    print("Done ✓")

if __name__ == '__main__':
    main()
