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

## Options

Add to `~/.tmux.conf` to customize:

```tmux
# Number of save slots (default: 5)
set -g @resurrect_slots 5

# Override tmux-resurrect default keybindings (default: on)
set -g @resurrect_slots_override_default_keys on

# Enable rename keybinding (default: on)
set -g @resurrect_slots_enable_rename on
```

## How It Works

1. **Save**: Triggers tmux-resurrect save, then copies the save file into an available slot. If all slots are full, an fzf popup lets you pick which slot to overwrite.
2. **Restore**: Opens an fzf popup showing all saved slots sorted by time. The most recent slot is preselected. Selecting a slot symlinks it as tmux-resurrect's `last` file and triggers restore.
3. **Rename**: Opens an fzf popup to pick a slot, then prompts for a new label.

## Slot Display Format

```
[1] 2026-02-17 18:30:45 | my-project | main(3),dev(2)
[2] 2026-02-16 09:15:00 | before-refactor | main(5)
[3] (empty)
```

Each row shows: slot number, timestamp, label, and session summary (session name with window count).

## Troubleshooting

**fzf popup not appearing**
- Ensure fzf is installed: `which fzf`
- Ensure tmux version supports popups: `tmux -V` (3.2+)

**Save not working**
- Check tmux-resurrect is installed and working: `prefix + Ctrl-s` should save without this plugin
- Check resurrect directory exists: `ls ~/.tmux/resurrect/`

**Slots directory**
- Slot data is stored in `~/.tmux/resurrect/slots/`
- To reset: `rm -rf ~/.tmux/resurrect/slots/`

## License

[MIT](LICENSE)
