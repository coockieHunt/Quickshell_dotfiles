#!/usr/bin/env bash
# Used by: 1 file(s)
LOCK="$HOME/.local/share/quickshell-lockscreen"
THEME="${1:-$(cat "$HOME/.config/qylock/theme" 2>/dev/null)}"
THEME="${THEME:-material-you-dark}"

pgrep -f "quickshell.*lock_shell.qml" >/dev/null && exit 0
[ -n "$WAYLAND_DISPLAY" ] || exit 1

if [ ! -f "$LOCK/themes_link/$THEME/Main.qml" ]; then
    notify-send -u critical "Lockscreen" "Thème introuvable : $THEME"
    exit 1
fi

exec "$LOCK/lock.sh" "$THEME"
