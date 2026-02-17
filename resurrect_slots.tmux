#!/usr/bin/env bash
# resurrect_slots.tmux — entry point for tmux-resurrect-slots plugin

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Option helpers ──────────────────────────────────────

get_tmux_option() {
  local option="${1}"
  local default_value="${2}"
  local value
  value=$(tmux show-option -gqv "${option}" 2>/dev/null)
  echo "${value:-${default_value}}"
}

# ── Read options ────────────────────────────────────────

slot_count=$(get_tmux_option "@resurrect_slots" "5")
override_keys=$(get_tmux_option "@resurrect_slots_override_default_keys" "on")
enable_rename=$(get_tmux_option "@resurrect_slots_enable_rename" "on")
enable_list=$(get_tmux_option "@resurrect_slots_enable_list" "on")

# ── Bind keys ───────────────────────────────────────────

if [ "${override_keys}" = "on" ]; then
  tmux bind-key C-s run-shell "${CURRENT_DIR}/scripts/save.sh"
  tmux bind-key C-r run-shell "${CURRENT_DIR}/scripts/restore.sh"
fi

if [ "${enable_rename}" = "on" ]; then
  tmux bind-key C-e run-shell "${CURRENT_DIR}/scripts/rename.sh"
fi

if [ "${enable_list}" = "on" ]; then
  tmux bind-key C-f run-shell "${CURRENT_DIR}/scripts/list.sh"
fi

# ── Initialize slots ───────────────────────────────────

# Source lib and meta to initialize slot directory and meta.tsv
source "${CURRENT_DIR}/scripts/lib.sh"
source "${CURRENT_DIR}/scripts/meta.sh"
ensure_dirs
init_meta "${slot_count}"
