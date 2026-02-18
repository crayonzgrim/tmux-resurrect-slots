#!/usr/bin/env bash
# restore.sh — slot-based restore for tmux-resurrect-slots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=meta.sh
source "${SCRIPT_DIR}/meta.sh"

# ── Find tmux-resurrect restore script ─────────────────

find_resurrect_restore_script() {
  local candidates=(
    "${TMUX_PLUGIN_MANAGER_PATH}/tmux-resurrect/scripts/restore.sh"
    "${HOME}/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
    "${XDG_DATA_HOME:-${HOME}/.local/share}/tmux/plugins/tmux-resurrect/scripts/restore.sh"
  )

  for candidate in "${candidates[@]}"; do
    if [ -x "${candidate}" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

# ── Main ───────────────────────────────────────────────

main() {
  if ! acquire_lock; then
    return 1
  fi
  setup_lock_trap

  local slot_count
  slot_count=$(get_slot_count)
  init_meta "${slot_count}"

  # Check if any slot has data
  local latest_id
  latest_id=$(get_latest_slot_id)
  if [ -z "${latest_id}" ]; then
    display_msg "resurrect-slots: no saved slots"
    return 0
  fi

  local target_slot=""

  if has_fzf; then
    # Build rows and show picker
    local rows
    rows=$(build_fzf_rows_for_restore)

    if [ -z "${rows}" ]; then
      display_msg "resurrect-slots: no saved slots"
      return 0
    fi

    # Latest slot is first row (sorted by epoch desc)
    local chosen
    chosen=$(echo "${rows}" | fzf_popup_select "Restore:" 1 "Select slot to restore" "" "40%" "38%")
    if [ -z "${chosen}" ]; then
      display_msg "resurrect-slots: restore cancelled"
      return 0
    fi

    target_slot=$(extract_slot_id_from_row "${chosen}")
  else
    # No fzf — auto-select latest
    target_slot="${latest_id}"
  fi

  # Verify slot file exists
  local slot_dir
  slot_dir=$(get_slot_dir)
  local slot_file="${slot_dir}/slot${target_slot}.txt"

  if [ ! -f "${slot_file}" ]; then
    display_msg "resurrect-slots: slot ${target_slot} file not found"
    return 1
  fi

  # Symlink slot file as resurrect's "last"
  local resurrect_dir
  resurrect_dir=$(get_resurrect_dir)
  ln -sf "${slot_file}" "${resurrect_dir}/last"

  # Run tmux-resurrect restore
  local resurrect_restore
  resurrect_restore=$(find_resurrect_restore_script)
  if [ -z "${resurrect_restore}" ]; then
    display_msg "resurrect-slots: tmux-resurrect restore script not found"
    return 1
  fi

  "${resurrect_restore}" >/dev/null 2>&1

  display_msg "resurrect-slots: restored from slot ${target_slot}"
}

main
