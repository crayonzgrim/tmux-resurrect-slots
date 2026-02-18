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

  local slot_dir
  slot_dir=$(get_slot_dir)
  local meta_script="${SCRIPT_DIR}/meta.sh"

  # Build preview command
  local preview_cmd
  preview_cmd="
    slot_id=\$(echo {} | sed 's/^\\[//;s/\\].*//')
    slot_file='${slot_dir}/slot'\"\${slot_id}\"'.txt'
    meta_file='${slot_dir}/meta.tsv'

    if [ ! -f \"\${slot_file}\" ]; then
      echo '(empty slot)'
      exit 0
    fi

    awk -F'\t' -v id=\"\${slot_id}\" '
      \$1==id {
        print \"Saved: \" \$3
        if (\$4 != \"\") print \"Label: \" \$4
        print \"\"
      }
    ' \"\${meta_file}\"

    echo 'Sessions / Windows'
    echo '──────────────────────────'

    awk -F'\t' '
      \$1==\"window\" {
        sess=\$2; wname=\$4
        sub(/^:/, \"\", wname)
        wins[sess] = (wins[sess] ? wins[sess] \", \" : \"\") wname
      }
      END {
        for (s in wins) printf \"  %s: [%s]\\n\", s, wins[s]
      }
    ' \"\${slot_file}\"

    echo ''
    echo 'Pane Paths'
    echo '──────────────────────────'

    awk -F'\t' '
      \$1==\"pane\" {
        path=\$8; sub(/^:/, \"\", path)
        if (!seen[path]++) printf \"  %s\\n\", path
      }
    ' \"\${slot_file}\"

    echo ''
    size=\$(wc -c < \"\${slot_file}\" | tr -d ' ')
    echo \"Size: \${size} bytes\"
  "

  # Loop: re-open after delete
  local rows
  rows=$(build_fzf_rows_for_overwrite)

  while true; do
    local result=""
    result=$(echo "${rows}" | FZF_DEFAULT_OPTS= fzf-tmux -p -w 80% -h 50% -- \
      --ansi --no-multi --cycle \
      --pointer "▶" --no-info --no-separator \
      --layout reverse --prompt "" \
      --bind "j:down,k:up,q:abort" \
      --expect=d \
      --header "View slots (d: delete, q: close)" \
      --preview "${preview_cmd}" --preview-window "right:50%:wrap") || true

    local key selection
    key=$(head -1 <<< "${result}")
    selection=$(sed -n '2p' <<< "${result}")

    if [ "${key}" = "d" ] && [ -n "${selection}" ]; then
      local slot_id="${selection#\[}"
      slot_id="${slot_id%%\]*}"

      # Skip if empty slot
      local slot_file="${slot_dir}/slot${slot_id}.txt"
      if [ -f "${slot_file}" ]; then
        clear_slot "${slot_id}"
      fi

      rows=$(build_fzf_rows_for_overwrite)
      continue
    fi

    break
  done
}

main
