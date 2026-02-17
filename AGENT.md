# Agent Instructions for tmux-resurrect-slots

Rules for AI agents working on this project.

## Source of Truth

- `plan.md` is the implementation spec. Always check it before writing code.
- `CLAUDE.md` has project conventions. Follow them.

## Shell Scripting Rules

1. **shellcheck must pass** — run `shellcheck scripts/*.sh` after any edit
2. **No GNU-only flags** — `sed -i ''` on macOS vs `sed -i` on Linux; avoid both, prefer writing to temp file
3. **macOS date compatibility** — no `date -d`, no `%N` nanoseconds; stick to `date +"%Y-%m-%d %H:%M:%S"`
4. **Quote everything** — `"${var}"`, not `$var`
5. **Use `local`** — all function variables must be `local`
6. **Avoid subshell pipelines for state** — variables set in a pipeline subshell don't propagate; use temp files or `< <()` if bash

## fzf Fallback

Every UI path must handle fzf being absent:
- Save: if slots full and no fzf → display message and cancel
- Restore: if no fzf → auto-select latest slot
- Rename: requires fzf → display message and exit if missing

## meta.tsv Format

```
slot_id<TAB>epoch<TAB>iso<TAB>label<TAB>session_summary
```

- Fields are tab-separated
- Empty slots have epoch=0, empty label and summary
- Never reorder columns; append new columns at the end if needed
- Read with `while IFS=$'\t' read -r ...`

## Lock Protocol

- Acquire lock before any slot file or meta.tsv operation
- Release lock in trap on EXIT
- Use flock if available, mkdir fallback otherwise
- Lock scope: per-operation (save/restore/rename), not global

## tmux-resurrect Integration

- Locate resurrect's save.sh/restore.sh:
  1. `$TMUX_PLUGIN_MANAGER_PATH/tmux-resurrect/scripts/`
  2. `~/.tmux/plugins/tmux-resurrect/scripts/`
- Use resurrect's `last` symlink as the bridge:
  - After save: cp latest resurrect file to slot
  - Before restore: ln -sf slot file to `last`

## File Operations

- `cp` to store slot files (not mv — keep original intact)
- `ln -sf` to update `last` symlink
- Always use absolute paths for symlinks

## Do NOT

- Add complex dependencies (python, node, etc.)
- Use `eval` or dynamic command construction
- Modify tmux-resurrect's files directly
- Break the meta.tsv schema without migration plan
- Use `rm -rf` on any resurrect directory
- Create files outside `~/.tmux/resurrect/slots/`
