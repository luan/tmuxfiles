#!/usr/bin/env bash
# Switch to prev/next session using custom order
dir=$1
current=$(tmux display-message -p '#S')
sessions=($(~/.config/tmux/scripts/session-order.sh))
count=${#sessions[@]}

for i in "${!sessions[@]}"; do
  if [ "${sessions[$i]}" = "$current" ]; then
    if [ "$dir" = "prev" ]; then
      idx=$(( (i - 1 + count) % count ))
    else
      idx=$(( (i + 1) % count ))
    fi
    tmux switch-client -t "${sessions[$idx]}"
    exit 0
  fi
done
