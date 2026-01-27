#!/bin/bash
cur=$(tmux display-message -p '#S')
purple=$(tmux show -gqv @thm_mauve)
gray=$(tmux show -gqv @thm_overlay_0)
result=$(tmux list-sessions -F '#S' | while read s; do
  if [ "$s" = "$cur" ]; then
    printf '#[bold,fg=%s]%s#[nobold,fg=%s]' "$purple" "$s" "$gray"
  else
    printf '%s' "$s"
  fi
  printf ' · '
done | sed 's/ · $//')
printf '#[fg=%s]%s#[default]' "$gray" "$result"
