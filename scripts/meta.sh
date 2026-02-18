#!/usr/bin/env bash
# meta.sh — meta.tsv management for tmux-resurrect-slots

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

_meta_path() {
  echo "$(get_slot_dir)/meta.tsv"
}

# Initialize meta.tsv with empty slots if it doesn't exist.
# Args: slot_count
init_meta() {
  local slot_count="${1}"
  local meta_path
  meta_path=$(_meta_path)
  ensure_dirs

  if [ -f "${meta_path}" ]; then
    return 0
  fi

  local i
  for i in $(seq 1 "${slot_count}"); do
    printf '%s\t%s\t%s\t%s\t%s\n' "${i}" "0" "" "" "" >> "${meta_path}"
  done
}

# Read meta.tsv and emit normalized rows to stdout.
# Output: slot_id<TAB>epoch<TAB>iso<TAB>label<TAB>session_summary
read_meta() {
  local meta_path
  meta_path=$(_meta_path)

  if [ ! -f "${meta_path}" ]; then
    return 1
  fi

  while IFS=$'\t' read -r slot_id epoch iso label summary; do
    # Normalize: ensure epoch defaults to 0
    epoch="${epoch:-0}"
    printf '%s\t%s\t%s\t%s\t%s\n' "${slot_id}" "${epoch}" "${iso}" "${label}" "${summary}"
  done < "${meta_path}"
}

# Update a slot's metadata.
# Args: slot_id, epoch, iso, label, session_summary
update_slot_meta() {
  local target_id="${1}"
  local new_epoch="${2}"
  local new_iso="${3}"
  local new_label="${4}"
  local new_summary="${5}"
  local meta_path
  meta_path=$(_meta_path)
  local tmp_path="${meta_path}.tmp"

  while IFS=$'\t' read -r slot_id epoch iso label summary; do
    if [ "${slot_id}" = "${target_id}" ]; then
      printf '%s\t%s\t%s\t%s\t%s\n' "${slot_id}" "${new_epoch}" "${new_iso}" "${new_label}" "${new_summary}"
    else
      printf '%s\t%s\t%s\t%s\t%s\n' "${slot_id}" "${epoch}" "${iso}" "${label}" "${summary}"
    fi
  done < "${meta_path}" > "${tmp_path}"

  mv "${tmp_path}" "${meta_path}"
}

# Update only the label for a slot.
# Args: slot_id, new_label
set_slot_label() {
  local target_id="${1}"
  local new_label="${2}"
  local meta_path
  meta_path=$(_meta_path)
  local tmp_path="${meta_path}.tmp"

  while IFS=$'\t' read -r slot_id epoch iso label summary; do
    if [ "${slot_id}" = "${target_id}" ]; then
      printf '%s\t%s\t%s\t%s\t%s\n' "${slot_id}" "${epoch}" "${iso}" "${new_label}" "${summary}"
    else
      printf '%s\t%s\t%s\t%s\t%s\n' "${slot_id}" "${epoch}" "${iso}" "${label}" "${summary}"
    fi
  done < "${meta_path}" > "${tmp_path}"

  mv "${tmp_path}" "${meta_path}"
}

# Clear a slot: reset meta to empty and delete slot file.
# Args: slot_id
clear_slot() {
  local target_id="${1}"
  update_slot_meta "${target_id}" "0" "" "" ""

  local slot_file
  slot_file="$(get_slot_dir)/slot${target_id}.txt"
  rm -f "${slot_file}"
}

# Get the slot_id with the highest epoch (most recent save).
# Returns: slot_id on stdout, or empty if no saves exist
get_latest_slot_id() {
  local best_id=""
  local best_epoch=0

  while IFS=$'\t' read -r slot_id epoch _iso _label _summary; do
    epoch="${epoch:-0}"
    if [ "${epoch}" -gt "${best_epoch}" ]; then
      best_epoch="${epoch}"
      best_id="${slot_id}"
    fi
  done < "$(_meta_path)"

  echo "${best_id}"
}

# Get the first empty slot id (epoch == 0).
# Returns: slot_id on stdout, or empty if all slots are used
get_first_empty_slot_id() {
  while IFS=$'\t' read -r slot_id epoch _iso _label _summary; do
    if [ "${epoch:-0}" = "0" ]; then
      echo "${slot_id}"
      return 0
    fi
  done < "$(_meta_path)"

  return 1
}

# Build fzf display rows for restore (sorted by epoch desc, only non-empty).
# Output: "[K] YYYY-MM-DD HH:MM:SS | label | summary" per line
build_fzf_rows_for_restore() {
  local rows=()
  local ids=()

  while IFS=$'\t' read -r slot_id epoch iso label summary; do
    epoch="${epoch:-0}"
    if [ "${epoch}" = "0" ]; then
      continue
    fi
    # Convert ISO to display timestamp (strip T and timezone)
    local display_ts="${iso}"
    display_ts="${display_ts/T/ }"
    display_ts="${display_ts%+*}"
    display_ts="${display_ts%-*:*}"
    # Handle timezone offset format
    if [[ "${iso}" =~ T.*[+-][0-9]{4}$ ]]; then
      display_ts="${iso/T/ }"
      display_ts="${display_ts%[+-]*}"
    fi

    local row
    row=$(printf '[%s] %s' "${slot_id}" "${display_ts}")
    if [ -n "${label}" ]; then
      row="${row} | ${label}"
    fi
    if [ -n "${summary}" ]; then
      row="${row} | ${summary}"
    fi

    rows+=("${epoch}:${row}")
    ids+=("${slot_id}")
  done < "$(_meta_path)"

  # Sort by epoch descending
  local sorted
  sorted=$(printf '%s\n' "${rows[@]}" | sort -t: -k1 -rn)

  while IFS=: read -r _epoch row; do
    echo "${row}"
  done <<< "${sorted}"
}

# Build fzf display rows for overwrite picker (all slots).
# Output: "[K] YYYY-MM-DD HH:MM:SS | label | summary" or "[K] (empty)"
build_fzf_rows_for_overwrite() {
  while IFS=$'\t' read -r slot_id epoch iso label summary; do
    epoch="${epoch:-0}"
    if [ "${epoch}" = "0" ]; then
      printf '[%s] (empty)\n' "${slot_id}"
      continue
    fi

    local display_ts="${iso}"
    display_ts="${display_ts/T/ }"
    if [[ "${iso}" =~ T.*[+-][0-9]{4}$ ]]; then
      display_ts="${iso/T/ }"
      display_ts="${display_ts%[+-]*}"
    fi

    local row
    row=$(printf '[%s] %s' "${slot_id}" "${display_ts}")
    if [ -n "${label}" ]; then
      row="${row} | ${label}"
    fi
    if [ -n "${summary}" ]; then
      row="${row} | ${summary}"
    fi

    echo "${row}"
  done < "$(_meta_path)"
}

# Extract slot_id from an fzf display row: "[K] ..." -> K
extract_slot_id_from_row() {
  local row="${1}"
  local id
  id="${row#\[}"
  id="${id%%\]*}"
  echo "${id}"
}

# ── CLI interface (for tmux run-shell callbacks) ───────

# When called directly: meta.sh <command> [args...]
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    set_label)
      # meta.sh set_label <slot_id> <label>
      if [ -z "${2:-}" ]; then
        exit 1
      fi
      slot_count=$(get_slot_count)
      init_meta "${slot_count}"
      set_slot_label "${2}" "${3:-}"
      tmux display-message "resurrect-slots: slot ${2} renamed to '${3:-}'"
      ;;
    clear)
      # meta.sh clear <slot_id>
      if [ -z "${2:-}" ]; then
        exit 1
      fi
      slot_count=$(get_slot_count)
      init_meta "${slot_count}"
      clear_slot "${2}"
      tmux display-message "resurrect-slots: slot ${2} cleared"
      ;;
    rows)
      # meta.sh rows — output fzf rows for overwrite picker
      slot_count=$(get_slot_count)
      init_meta "${slot_count}"
      build_fzf_rows_for_overwrite
      ;;
    *)
      echo "Usage: meta.sh {set_label|clear|rows} [args...]" >&2
      exit 1
      ;;
  esac
fi
