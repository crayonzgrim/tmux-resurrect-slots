## Implementation Tasks — tmux-resurrect-slots v0.1.0

### Goal
Implement slot-based save/restore UI for tmux-resurrect using fzf-tmux popup.
Keys:
- Prefix+Ctrl-s: save (slot-managed)
- Prefix+Ctrl-r: restore (always popup; latest preselected)
- Prefix+Ctrl-e: rename

### Constraints
- Must work with tmux-resurrect (required)
- Use cp to store slot files
- Slot count fixed (default 5)
- When full: must show overwrite picker UI (ESC cancel allowed)
- Display timestamp with seconds and session summary (session(window_count))
- Public GitHub repo quality: README + MIT license

### Files
1) resurrect_slots.tmux
- Read options with sane defaults:
  - @resurrect_slots (default 5)
  - @resurrect_slots_override_default_keys (default on)
  - @resurrect_slots_enable_rename (default on)
- Bind keys:
  - C-s -> scripts/save.sh
  - C-r -> scripts/restore.sh
  - C-e -> scripts/rename.sh (if enabled)
- Determine plugin path robustly via current script location

2) scripts/lib.sh
- Functions:
  - get_resurrect_dir(): use @resurrect-dir or ~/.tmux/resurrect
  - get_slot_dir(): "${RESURRECT_DIR}/slots"
  - ensure_dirs()
  - now_timestamp_label(): "YYYY-MM-DD HH:MM:SS" (use date)
  - now_iso_with_tz(): ISO8601 with timezone
  - has_fzf(): check command exists
  - fzf_popup_select(lines, prompt, preselect_index)
    - use fzf-tmux -p -w 62% -h 38% (if available)
  - display_msg()
  - lock/unlock (flock if available else mkdir lock)

3) scripts/meta.sh
- Manage meta.tsv:
  - init_meta(slots)
  - read_meta() -> emit normalized rows
  - update_slot_meta(slot_id, epoch, iso, label, session_summary)
  - set_slot_label(slot_id, new_label)
  - get_latest_slot_id() by epoch
  - build_fzf_rows_for_restore(): "[K] TS | label | summary"
  - build_fzf_rows_for_overwrite(): same, but include all slots

4) scripts/save.sh
- Steps:
  - lock
  - call tmux-resurrect save.sh (find it relative to TPM plugins dir; assume ~/.tmux/plugins/tmux-resurrect/scripts/save.sh by default, but try to resolve via $TMUX_PLUGIN_MANAGER_PATH or common paths)
  - find latest resurrect file:
    - prefer RESURRECT_DIR/last if exists (resolve symlink)
    - else newest tmux_resurrect_* file
  - collect session_summary from tmux:
    - list sessions
    - for each: window count
    - format "name(count),..."
  - choose slot:
    - if any empty slot file missing -> lowest id
    - else if fzf exists -> overwrite picker UI (ESC cancels)
    - else cancel with message
  - cp latest -> slotK.txt
  - update meta for slotK with now timestamps and label
  - display-message success
  - unlock

5) scripts/restore.sh
- Steps:
  - lock
  - ensure meta exists
  - if no slots have data -> message and exit
  - if fzf exists:
    - build rows sorted by epoch desc
    - preselect latest slot row
    - popup select -> chosen slot or cancel
  - else:
    - choose latest slot automatically
  - ln -sf slotK.txt -> RESURRECT_DIR/last
  - call tmux-resurrect restore.sh
  - display-message success
  - unlock

6) scripts/rename.sh
- Steps:
  - lock
  - require fzf (if 없으면 안내)
  - popup choose slot
  - tmux command-prompt to input label
  - update meta label only
  - display-message
  - unlock

7) README.md (MVP quality)
- Include:
  - Description
  - Requirements
  - Installation (TPM)
  - Keybindings
  - Options
  - Troubleshooting

8) LICENSE (MIT)

### Notes
- Keep code POSIX-ish; target macOS too.
- Avoid GNU-only flags; if unavoidable, implement portable alternatives.
- Use `date` carefully on macOS; prefer `date +"%Y-%m-%d %H:%M:%S"` and ISO via `date +"%Y-%m-%dT%H:%M:%S%z"` then format into `+09:00` if needed, or keep `%z`.

---

### 참고 URL
tmux resurrect : https://github.com/tmux-plugins/tmux-resurrect
harpoon : https://github.com/ThePrimeagen/harpoon
oil : https://github.com/stevearc/oil.nvim
tmux-sessionX : https://github.com/omerxx/tmux-sessionx
tmux-fzf : https://github.com/sainnhe/tmux-fzf


