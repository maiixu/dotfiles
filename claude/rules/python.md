# Python Rules

## Testing
- All tests must be offline: no network calls, no API calls, no state file writes
- Use `pytest` (not `unittest`); run with `python3 -m pytest`
- Mock external calls at the boundary (HTTP, subprocess), not internal logic

## Style
- No type annotations unless the file already uses them throughout
- No docstrings on functions unless the logic isn't self-evident
- No `__all__` exports unless the module is a library

## CLI scripts
- Flags use `argparse`; defaults should make the script safe to run without arguments
- Secrets come from `.env.local` via `python-dotenv` or `os.environ`; never hardcoded
