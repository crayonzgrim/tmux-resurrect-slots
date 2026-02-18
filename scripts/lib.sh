#!/usr/bin/env bash
# lib.sh — shared utilities for tmux-resurrect-slots

# Resurrect directory (respect user override)
get_resurrect_dir() {
  local dir
  dir=$(tmux show-option -gqv @resurrect-dir 2>/dev/null)
  if [ -z "${dir}" ]; then
    echo "${HOME}/.tmux/resurrect"
  else
    # Expand ~ if present
    echo "${dir/#\~/$HOME}"
  fi
}

# Slot storage directory
get_slot_dir() {
  echo "$(get_resurrect_dir)/slots"
}

# Ensure required directories exist
ensure_dirs() {
  local slot_dir
  slot_dir=$(get_slot_dir)
  mkdir -p "${slot_dir}"
}

# Get configured slot count
get_slot_count() {
  local count
  count=$(tmux show-option -gqv @resurrect_slots 2>/dev/null)
  echo "${count:-5}"
}

# ── Timestamps ──────────────────────────────────────────

# Human-readable timestamp: "YYYY-MM-DD HH:MM:SS"
now_timestamp_label() {
  date +"%Y-%m-%d %H:%M:%S"
}

# ISO 8601 with timezone: "2026-02-17T18:30:45+0900"
now_iso_with_tz() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

# Unix epoch seconds
now_epoch() {
  date +"%s"
}

# ── fzf ─────────────────────────────────────────────────

# Check if fzf is available
has_fzf() {
  command -v fzf >/dev/null 2>&1
}

# Show fzf-tmux popup and return selected line.
# Args: prompt, preselect_index (1-based), header, preview_cmd, popup_width, popup_height
# Returns: selected line on stdout, exit 1 if cancelled
fzf_popup_select() {
  local prompt="${1:-Select:}"
  local preselect_index="${2:-1}"
  local header="${3:-}"
  local preview_cmd="${4:-}"
  local popup_w="${5:-80%}"
  local popup_h="${6:-50%}"

  local fzf_opts=(
    --ansi
    --no-multi
    --cycle
    --pointer "▶"
    --no-info
    --no-separator
    --layout reverse
    --prompt ""
    --disabled
    --bind "change:clear-query"
    --bind "j:down,k:up,q:abort"
  )

  if [ -n "${preview_cmd}" ]; then
    fzf_opts+=(--preview "${preview_cmd}" --preview-window "right:50%:wrap")
  else
    fzf_opts+=(--no-preview)
  fi

  if [ -n "${header}" ]; then
    fzf_opts+=(--header "${header}")
  fi

  if command -v fzf-tmux >/dev/null 2>&1; then
    FZF_DEFAULT_OPTS= fzf-tmux -p -w "${popup_w}" -h "${popup_h}" -- "${fzf_opts[@]}"
  else
    FZF_DEFAULT_OPTS= fzf "${fzf_opts[@]}"
  fi
}

# ── Display ─────────────────────────────────────────────

# Show tmux display-message
display_msg() {
  tmux display-message "$1"
}

# ── Lock ────────────────────────────────────────────────

_lock_path() {
  echo "$(get_slot_dir)/.lock"
}

# Acquire lock. Sets _LOCK_FD if flock is used.
acquire_lock() {
  local lock_path
  lock_path=$(_lock_path)
  ensure_dirs

  if command -v flock >/dev/null 2>&1; then
    # flock-based locking
    exec 9>"${lock_path}"
    if ! flock -n 9; then
      display_msg "resurrect-slots: another operation in progress"
      return 1
    fi
  else
    # mkdir-based fallback
    local attempts=0
    while ! mkdir "${lock_path}.d" 2>/dev/null; do
      attempts=$((attempts + 1))
      if [ "${attempts}" -ge 10 ]; then
        display_msg "resurrect-slots: another operation in progress"
        return 1
      fi
      sleep 0.2
    done
  fi
  return 0
}

# Release lock
release_lock() {
  local lock_path
  lock_path=$(_lock_path)

  if command -v flock >/dev/null 2>&1; then
    exec 9>&-
    rm -f "${lock_path}"
  else
    rmdir "${lock_path}.d" 2>/dev/null
  fi
}

# Setup trap to release lock on exit
setup_lock_trap() {
  trap 'release_lock' EXIT INT TERM
}
