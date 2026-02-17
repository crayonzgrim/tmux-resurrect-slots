# tmux-resurrect-slots

Slot-based save/restore for [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect).

Keep multiple tmux session snapshots in numbered slots (like game save slots) and pick which one to restore via fzf popup.

## Features

- **Multiple save slots** (default 5) — no more losing your previous saves
- **fzf popup UI** — browse slots with timestamps, labels, and session summaries
- **Overwrite picker** — when all slots are full, choose which to overwrite
- **Rename slots** — give meaningful labels to your saves
- **Auto fallback** — works without fzf (auto-selects latest slot)

## Requirements

- [tmux](https://github.com/tmux/tmux) 3.2+
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) (required)
- [fzf](https://github.com/junegunn/fzf) (optional, for popup UI)
- [TPM](https://github.com/tmux-plugins/tpm) (recommended for installation)

## Installation

### With TPM

Add to `~/.tmux.conf`:

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'crayonzgrim/tmux-resurrect-slots'
```

Then press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/crayonzgrim/tmux-resurrect-slots.git ~/.tmux/plugins/tmux-resurrect-slots
```

Add to `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-resurrect-slots/resurrect_slots.tmux
```

## Key Bindings

| Key | Action |
|-----|--------|
| `prefix + Ctrl-s` | Save to slot |
| `prefix + Ctrl-r` | Restore from slot (fzf popup) |
| `prefix + Ctrl-e` | Rename slot label |
| `prefix + Ctrl-f` | List saved slots |

## Options

Add to `~/.tmux.conf` to customize:

```tmux
# Number of save slots (default: 5)
set -g @resurrect_slots 5

# Override tmux-resurrect default keybindings (default: on)
set -g @resurrect_slots_override_default_keys on

# Enable rename keybinding (default: on)
set -g @resurrect_slots_enable_rename on

# Enable list keybinding (default: on)
set -g @resurrect_slots_enable_list on
```

## Usage

### Saving a Session

1. Press `prefix + Ctrl-s`
2. tmux-resurrect saves the current session first
3. If an empty slot is available, the save is stored there automatically (lowest slot number)
4. If all slots are full, an fzf popup appears — pick which slot to overwrite (press `ESC` to cancel)
5. A confirmation message appears: `"saved to slot N"`

### Restoring a Session

1. Press `prefix + Ctrl-r`
2. An fzf popup shows all saved slots, sorted by most recent first
3. The latest save is preselected — press `Enter` to restore it, or navigate to a different slot
4. Press `ESC` to cancel
5. Without fzf installed, the most recent slot is restored automatically

### Viewing Saved Slots

1. Press `prefix + Ctrl-f`
2. An fzf popup shows all slots (saved and empty)
3. Select a slot to see its details (timestamp, label, session summary, file size)
4. Press `ESC` to close without any action
5. Without fzf installed, a summary message is shown (e.g., `"3/5 slots used"`)

### Renaming a Slot

1. Press `prefix + Ctrl-e`
2. Pick a slot from the fzf popup
3. A tmux prompt appears — type a label (e.g., `before-refactor`) and press `Enter`
4. The label appears next to the slot in future popups

### Slot Display Format

```
[1] 2026-02-17 18:30:45 | my-project | main(3),dev(2)
[2] 2026-02-16 09:15:00 | before-refactor | main(5)
[3] (empty)
```

Each row shows: slot number, timestamp, label, and session summary (session name with window count).

## How It Works

- **Save**: Triggers tmux-resurrect save, then copies the save file into an available slot. When all slots are full, an fzf popup lets you pick which to overwrite.
- **Restore**: Symlinks the chosen slot file as tmux-resurrect's `last` file, then triggers tmux-resurrect restore.
- **Rename**: Updates the label in `meta.tsv` without touching the save file itself.
- **Data storage**: All slot data lives in `~/.tmux/resurrect/slots/` — a `meta.tsv` file tracks metadata and `slotN.txt` files hold the actual saves.

## Troubleshooting

**fzf popup not appearing**
- Ensure fzf is installed: `which fzf`
- Ensure tmux version supports popups: `tmux -V` (3.2+)

**Save not working**
- Verify tmux-resurrect works on its own first
- Check resurrect directory exists: `ls ~/.tmux/resurrect/`

**Restore not working**
- Check that slot files exist: `ls ~/.tmux/resurrect/slots/`
- Verify the `last` symlink: `ls -la ~/.tmux/resurrect/last`

**Reset all slots**
- Remove the slots directory: `rm -rf ~/.tmux/resurrect/slots/`
- Slots will be re-initialized on next save

## License

[MIT](LICENSE)
