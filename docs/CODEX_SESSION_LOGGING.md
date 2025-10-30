# Codex Session Logging

Use the `scripts/log_codex_session.py` helper to capture a lightweight record
every time you collaborate with Codex in this repository. Each invocation
creates a Markdown entry inside `codex_sessions/` that includes the timestamp,
current branch/commit, any notes you provide, and (optionally) the local git
status and diff.

## Basic Workflow

1. Wrap up a Codex session.
2. Summarise what changed and run:
   ```bash
   scripts/log_codex_session.py "Short description" \
     -n "Key intent or outcome" \
     -n "Follow-up: add integration test" \
     --tags backend api
   ```
3. Commit the new file under `codex_sessions/` alongside your code changes.

The script creates one file per run using the pattern
`codex_sessions/YYYYMMDD-HHMMSS-your-title.md`.

## Options

- `-n/--note`: append multiple notes (one per flag). Lines are joined in the
  order they are provided.
- `--tags`: optional list of keywords to help with later filtering.
- `--skip-diff`: omit the full `git diff` patch from the log.
- `--skip-status`: omit the concise `git status --short` block.
- `--commit`: capture the patch for a specific commit (uses `git show`).
- `--output-dir`: write to a different directory if you want to archive logs
  elsewhere (defaults to `codex_sessions`).

### Example Output

```
# Payment flow cleanup

- Timestamp: 2025-10-30 05:27:36 UTC-07:00
- Branch: feature/checkout
- Commit: 4c2f1d7
- Tags: backend, checkout

## Notes
Refined error handling for PSP timeouts. Follow up with integration test in tests/payments/.

## Git Status
```text
 M backend/payments/processor.py
?? tests/payments/test_timeouts.py
```

## Git Diff
```diff
diff --git a/backend/payments/processor.py b/backend/payments/processor.py
...
```
```

## Tips

- Run the script immediately after you finish working with Codex so notes are
  fresh.
- Keep logs in version control so teammates can trace AI-assisted changes.
- Pair the session entry with regular commits for a complete paper trail.

## Automatic Logging on Commit

If you prefer zero manual steps, this repository includes a ready-to-use
`post-commit` hook under `.githooks/`. Enable it once per clone:

```bash
git config core.hooksPath .githooks
```

Every commit will then append a session entry that uses the commit summary as
the title, records the full patch via `--commit`, and includes the commit hash
plus any body lines as notes. To skip logging for a specific commit, set
`SKIP_CODEX_SESSION_LOG=1` in your environment before running `git commit`.
