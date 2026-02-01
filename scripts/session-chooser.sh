#!/bin/bash
# Session chooser with fzf - supports alt-h to toggle hidden
SCRIPTS_DIR="$HOME/.config/tmux/scripts"
ORDER_FILE="$HOME/.config/tmux/session-order"
HIDDEN_FILE="$HOME/.config/tmux/session-hidden"
touch "$ORDER_FILE" "$HIDDEN_FILE"

build_list() {
  current=$(tmux display-message -p '#S')
  all_sessions=$(tmux list-sessions -F '#S')

  # Build ordered list (include all sessions)
  sessions=""
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    echo "$all_sessions" | grep -qxF "$s" && sessions="$sessions$s"$'\n'
  done < "$ORDER_FILE"

  # Add new sessions to order file
  echo "$all_sessions" | while IFS= read -r s; do
    [ -z "$s" ] && continue
    grep -qxF "$s" "$ORDER_FILE" 2>/dev/null || echo "$s" >> "$ORDER_FILE"
  done

  # Rebuild with any new sessions
  sessions=""
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    echo "$all_sessions" | grep -qxF "$s" && sessions="$sessions$s"$'\n'
  done < "$ORDER_FILE"

  # Build display with indices, current marker, and hidden indicator
  i=1
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    line="$i: $s"
    if grep -qxF "$s" "$HIDDEN_FILE"; then
      line="$line [H]"
    fi
    if [ "$s" = "$current" ]; then
      line="$line <-"
    fi
    echo "$line"
    i=$((i + 1))
  done <<< "$sessions"
}

if [ "$1" = "--popup" ]; then
  export -f build_list
  export ORDER_FILE HIDDEN_FILE SCRIPTS_DIR

  popup_bg=$(tmux show -gqv @popup_bg)
  selected=$(build_list | fzf \
    --height=100% \
    --layout=reverse \
    --prompt="session> " \
    --header="alt-h: toggle hidden" \
    --bind "alt-h:execute-silent($SCRIPTS_DIR/session-hide-toggle.sh {2})+reload(bash -c build_list)" \
    --color="bg:$popup_bg,bg+:$popup_bg")

  [ -z "$selected" ] && exit 0
  session=$(echo "$selected" | sed 's/^[0-9]*: //; s/ \[H\]//; s/ <-$//')
  [ -n "$session" ] && tmux switch-client -t "$session"
  exit 0
fi

# Launch popup
popup_bg=$(tmux show -gqv @popup_bg)
popup_border=$(tmux show -gqv @popup_border)
tmux display-popup -E -b rounded -w 80 -h 90% -x C -y C \
  -s "bg=$popup_bg" -S "fg=$popup_border,bg=$popup_bg" \
  "$0 --popup" || true
