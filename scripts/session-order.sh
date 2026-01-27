#!/bin/bash
# Returns sessions in custom order, appending any new sessions at the end
ORDER_FILE="$HOME/.config/tmux/session-order"
touch "$ORDER_FILE"

# Get all current sessions
current=$(tmux list-sessions -F '#S')

# Build ordered list
ordered=""
while read -r s; do
  [ -z "$s" ] && continue
  if echo "$current" | grep -qxF "$s"; then
    ordered="$ordered$s"$'\n'
  fi
done < "$ORDER_FILE"

# Append any sessions not in order file
while read -r s; do
  if ! grep -qxF "$s" "$ORDER_FILE"; then
    ordered="$ordered$s"$'\n'
    echo "$s" >> "$ORDER_FILE"
  fi
done <<< "$current"

printf '%s' "$ordered" | sed '/^$/d'
