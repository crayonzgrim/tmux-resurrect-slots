# tmux-resurrect-slots

Slot-based save/restore for [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect).

Keep multiple tmux session snapshots in numbered slots (like game save slots) and pick which one to restore via fzf popup.

## Features

- **Multiple save slots** (default 5) — no more losing your previous saves
- **fzf popup UI** — browse slots with timestamps, labels, and session summaries
- **Preview panel** — view session/window details and pane paths in the list view
- **Label on save** — name your saves right after saving (or skip with Enter)
- **Delete slots** — press `d` in the list view to clear a slot
- **Overwrite picker** — when all slots are full, choose which to overwrite
- **Rename slots** — give meaningful labels to your saves anytime
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
| `prefix + Ctrl-r` | Restore from slot |
| `prefix + Ctrl-e` | Rename slot label |
| `prefix + Ctrl-f` | List / manage slots |

### Inside the list popup (`prefix + Ctrl-f`)

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up / down |
| `d` | Delete selected slot |
| `q` | Close |

### Inside other popups (save overwrite, restore, rename)

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up / down |
| `Enter` | Select |
| `q` | Cancel |

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
2. If an empty slot is available, the save is stored automatically
3. If all slots are full, a popup appears — pick which slot to overwrite
4. After saving, a label prompt appears — type a name or press `Enter` to skip

### Restoring a Session

1. Press `prefix + Ctrl-r`
2. A popup shows all saved slots, sorted by most recent first
3. Navigate with `j`/`k`, press `Enter` to restore
4. Press `q` to cancel
5. Without fzf installed, the most recent slot is restored automatically

### Viewing and Managing Slots

1. Press `prefix + Ctrl-f`
2. A popup shows all slots with a preview panel on the right
3. The preview shows: timestamp, label, sessions/windows, pane paths, file size
4. Press `d` to delete the selected slot
5. Press `q` to close
6. Without fzf installed, a summary message is shown (e.g., `"3/5 slots used"`)

### Renaming a Slot

1. Press `prefix + Ctrl-e`
2. Pick a slot from the popup
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

- **Save**: Picks an empty slot (or prompts to overwrite), then triggers tmux-resurrect save, copies the save file into the slot, and prompts for a label.
- **Restore**: Symlinks the chosen slot file as tmux-resurrect's `last` file, then triggers tmux-resurrect restore.
- **List**: Shows all slots with a preview panel. Press `d` to delete a slot.
- **Rename**: Updates the label in `meta.tsv` without touching the save file.
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
