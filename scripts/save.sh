#!/usr/bin/env bash
# save.sh — slot-based save for tmux-resurrect-slots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=meta.sh
source "${SCRIPT_DIR}/meta.sh"

# ── Find tmux-resurrect save script ────────────────────

find_resurrect_save_script() {
  local candidates=(
    "${TMUX_PLUGIN_MANAGER_PATH}/tmux-resurrect/scripts/save.sh"
    "${HOME}/.tmux/plugins/tmux-resurrect/scripts/save.sh"
    "${HOME}/.config/tmux/plugins/tmux-resurrect/scripts/save.sh"
    "${XDG_DATA_HOME:-${HOME}/.local/share}/tmux/plugins/tmux-resurrect/scripts/save.sh"
  )

  for candidate in "${candidates[@]}"; do
    if [ -x "${candidate}" ]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

# ── Find latest resurrect file ─────────────────────────

find_latest_resurrect_file() {
  local resurrect_dir
  resurrect_dir=$(get_resurrect_dir)

  # Prefer "last" symlink
  local last_link="${resurrect_dir}/last"
  if [ -L "${last_link}" ]; then
    local target
    target=$(readlink "${last_link}" 2>/dev/null)
    # Handle relative symlinks
    if [ -n "${target}" ] && [[ "${target}" != /* ]]; then
      target="${resurrect_dir}/${target}"
    fi
    if [ -f "${target}" ]; then
      echo "${target}"
      return 0
    fi
  fi

  # Fallback: newest tmux_resurrect_* file
  local newest
  newest=$(ls -t "${resurrect_dir}"/tmux_resurrect_*.txt 2>/dev/null | head -1)
  if [ -n "${newest}" ]; then
    echo "${newest}"
    return 0
  fi

  return 1
}

# ── Collect session summary ────────────────────────────

collect_session_summary() {
  local sessions
  sessions=$(tmux list-sessions -F '#{session_name}:#{session_windows}' 2>/dev/null)

  local parts=()
  while IFS=: read -r name windows; do
    parts+=("${name}(${windows})")
  done <<< "${sessions}"

  local IFS=","
  echo "${parts[*]}"
}

# ── Main ───────────────────────────────────────────────

main() {
  # Acquire lock
  if ! acquire_lock; then
    return 1
  fi
  setup_lock_trap

  local slot_count
  slot_count=$(get_slot_count)

  # Ensure meta is initialized
  init_meta "${slot_count}"

  # Choose slot FIRST (before resurrect save) for fast popup response
  local target_slot=""

  # Check for empty slot first
  target_slot=$(get_first_empty_slot_id)

  if [ -z "${target_slot}" ]; then
    # All slots full — need overwrite picker
    if ! has_fzf; then
      display_msg "resurrect-slots: all slots full, fzf required to choose overwrite"
      return 1
    fi

    local rows
    rows=$(build_fzf_rows_for_overwrite)

    local chosen
    chosen=$(echo "${rows}" | fzf_popup_select "Overwrite:" 1 "All slots full — pick one to overwrite (q: cancel)" "" "40%" "38%")
    if [ -z "${chosen}" ]; then
      display_msg "resurrect-slots: save cancelled"
      return 0
    fi

    target_slot=$(extract_slot_id_from_row "${chosen}")
  fi

  # Run tmux-resurrect save
  local resurrect_save
  resurrect_save=$(find_resurrect_save_script)
  if [ -z "${resurrect_save}" ]; then
    display_msg "resurrect-slots: tmux-resurrect save script not found"
    return 1
  fi

  "${resurrect_save}" >/dev/null 2>&1
  sleep 0.3

  # Find the latest resurrect file
  local latest_file
  latest_file=$(find_latest_resurrect_file)
  if [ -z "${latest_file}" ]; then
    display_msg "resurrect-slots: no resurrect file found after save"
    return 1
  fi

  # Collect session info
  local summary
  summary=$(collect_session_summary)
  local epoch iso
  epoch=$(now_epoch)
  iso=$(now_iso_with_tz)

  # Copy resurrect file to slot
  local slot_dir
  slot_dir=$(get_slot_dir)
  cp "${latest_file}" "${slot_dir}/slot${target_slot}.txt"

  # Update meta (no label yet)
  update_slot_meta "${target_slot}" "${epoch}" "${iso}" "" "${summary}"

  # Prompt for label — Enter to skip
  tmux command-prompt -p "Saved to slot ${target_slot}. Label (Enter to skip):" \
    "run-shell \"bash '${SCRIPT_DIR}/meta.sh' set_label '${target_slot}' '%%'\""
}

main
