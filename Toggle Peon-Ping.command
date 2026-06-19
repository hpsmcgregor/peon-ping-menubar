#!/bin/bash
# Double-click to toggle peon-ping sounds on/off.
result="$(bash "$HOME/.claude/hooks/peon-ping/peon.sh" toggle)"
# Tell the SwiftBar menu-bar icon to update immediately.
open "swiftbar://refreshallplugins" >/dev/null 2>&1
echo ""
echo "  🔊  $result"
echo ""
# Briefly show the result, then close the Terminal window.
sleep 1.5
osascript -e 'tell application "Terminal" to close (every window whose name contains "Toggle Peon-Ping")' >/dev/null 2>&1 &
exit 0
