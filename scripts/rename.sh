#!/usr/bin/env bash
# rename.sh — rename slot label for tmux-resurrect-slots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=meta.sh
source "${SCRIPT_DIR}/meta.sh"

# ── Main ───────────────────────────────────────────────

main() {
  if ! acquire_lock; then
    return 1
  fi
  setup_lock_trap

  local slot_count
  slot_count=$(get_slot_count)
  init_meta "${slot_count}"

  # Require fzf for rename
  if ! has_fzf; then
    display_msg "resurrect-slots: fzf required for rename"
    return 1
  fi

  # Build rows (show all non-empty slots)
  local rows
  rows=$(build_fzf_rows_for_restore)

  if [ -z "${rows}" ]; then
    display_msg "resurrect-slots: no saved slots to rename"
    return 0
  fi

  # Pick slot
  local chosen
  chosen=$(echo "${rows}" | fzf_popup_select "Rename:" 1 "Select slot to rename" "" "40%" "38%")
  if [ -z "${chosen}" ]; then
    display_msg "resurrect-slots: rename cancelled"
    return 0
  fi

  local target_slot
  target_slot=$(extract_slot_id_from_row "${chosen}")

  # Release lock before command-prompt (it blocks)
  release_lock

  # Prompt for new label via tmux command-prompt
  tmux command-prompt -p "Label for slot ${target_slot}:" \
    "run-shell \"${SCRIPT_DIR}/meta.sh set_label ${target_slot} '%%'\""
}

main
