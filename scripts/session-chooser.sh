#!/bin/sh
# Stage 1: Prepare data and launch popup (called via run-shell)
# Stage 2: Run gum in popup (called via display-popup)

TMPFILE="/tmp/tmux-session-chooser"

if [ "$1" = "--popup" ]; then
  # Stage 2: Inside popup, just run gum
  selected=$(cat "$TMPFILE" | gum filter --placeholder="session" --height=10)
  rm -f "$TMPFILE"
  [ -z "$selected" ] && exit 0
  session=$(echo "$selected" | sed 's/^[0-9]*: //; s/ ←$//')
  [ -n "$session" ] && tmux switch-client -t "$session"
  exit 0
fi

# Stage 1: Prepare session list
ORDER_FILE="$HOME/.config/tmux/session-order"
current=$(tmux display-message -p '#S')
all_sessions=$(tmux list-sessions -F '#S')

# Build ordered list
sessions=""
if [ -f "$ORDER_FILE" ]; then
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    echo "$all_sessions" | grep -qxF "$s" && sessions="$sessions$s
"
  done < "$ORDER_FILE"
fi

# Add new sessions
echo "$all_sessions" | while IFS= read -r s; do
  [ -z "$s" ] && continue
  grep -qxF "$s" "$ORDER_FILE" 2>/dev/null || echo "$s" >> "$ORDER_FILE"
done

# Rebuild final list
sessions=""
[ -f "$ORDER_FILE" ] && while IFS= read -r s; do
  echo "$all_sessions" | grep -qxF "$s" && sessions="$sessions$s
"
done < "$ORDER_FILE"

# Build display with indices and write to temp file
i=1
: > "$TMPFILE"
for s in $sessions; do
  [ -z "$s" ] && continue
  if [ "$s" = "$current" ]; then
    echo "$i: $s ←" >> "$TMPFILE"
  else
    echo "$i: $s" >> "$TMPFILE"
  fi
  i=$((i + 1))
done

# Launch popup (popup will run stage 2)
popup_bg=$(tmux show -gqv @popup_bg)
popup_border=$(tmux show -gqv @popup_border)
tmux display-popup -E -b rounded -w 80 -h 90% -x C -y C -s "bg=$popup_bg" -S "fg=$popup_border,bg=$popup_bg" "$0 --popup" || true
