#!/usr/bin/env bash
# list.sh — view saved slots for tmux-resurrect-slots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
# shellcheck source=meta.sh
source "${SCRIPT_DIR}/meta.sh"

main() {
  local slot_count
  slot_count=$(get_slot_count)
  init_meta "${slot_count}"

  # Require fzf
  if ! has_fzf; then
    # No fzf — show summary via display-message
    local latest_id
    latest_id=$(get_latest_slot_id)
    if [ -z "${latest_id}" ]; then
      display_msg "resurrect-slots: no saved slots"
    else
      local used=0
      while IFS=$'\t' read -r _sid epoch _iso _label _summary; do
        if [ "${epoch:-0}" != "0" ]; then
          used=$((used + 1))
        fi
      done < "$(get_slot_dir)/meta.tsv"
      display_msg "resurrect-slots: ${used}/${slot_count} slots used (latest: slot ${latest_id})"
    fi
    return 0
  fi

  # Build rows (all slots, like overwrite view)
  local rows
  rows=$(build_fzf_rows_for_overwrite)

  if [ -z "${rows}" ]; then
    display_msg "resurrect-slots: no slots"
    return 0
  fi

  # Show fzf popup
  local chosen
  chosen=$(echo "${rows}" | fzf_popup_select "Slots:" 1 "Select slot for details (ESC to close)")
  if [ -z "${chosen}" ]; then
    return 0
  fi

  # Show selected slot detail
  local slot_id
  slot_id=$(extract_slot_id_from_row "${chosen}")

  local slot_dir
  slot_dir=$(get_slot_dir)
  local slot_file="${slot_dir}/slot${slot_id}.txt"

  if [ ! -f "${slot_file}" ]; then
    display_msg "resurrect-slots: slot ${slot_id} is empty"
    return 0
  fi

  # Read meta for this slot
  local detail=""
  while IFS=$'\t' read -r sid epoch iso label summary; do
    if [ "${sid}" = "${slot_id}" ]; then
      local size
      size=$(wc -c < "${slot_file}" | tr -d ' ')
      detail="Slot ${sid}"
      if [ -n "${label}" ]; then
        detail="${detail} | ${label}"
      fi
      detail="${detail} | ${iso} | ${summary} | ${size} bytes"
      break
    fi
  done < "$(get_slot_dir)/meta.tsv"

  display_msg "resurrect-slots: ${detail}"
}

main
