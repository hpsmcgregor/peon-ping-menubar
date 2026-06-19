#!/bin/bash
# Install the Peon-Ping SwiftBar menu-bar toggle.
#
# Copies the plugin + icon into SwiftBar's plugin directory, installs a
# LaunchAgent so SwiftBar starts at login, and registers the agent now.
#
# Prerequisites:
#   - SwiftBar       (brew install --cask swiftbar)
#   - peon-ping      (the `peon.sh` hook this plugin toggles)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SB="$HOME/Library/Application Support/SwiftBar"
PLUGINS="$SB/Plugins"
LA_DIR="$HOME/Library/LaunchAgents"
LA_PLIST="com.peonping.swiftbar.plist"

echo "==> Checking SwiftBar is installed"
if [ ! -d "/Applications/SwiftBar.app" ]; then
  echo "SwiftBar not found at /Applications/SwiftBar.app" >&2
  echo "Install it first:  brew install --cask swiftbar" >&2
  exit 1
fi

echo "==> Installing plugin + icon into SwiftBar"
mkdir -p "$PLUGINS"
cp "$REPO_DIR/plugins/peonping.10s.sh" "$PLUGINS/peonping.10s.sh"
chmod +x "$PLUGINS/peonping.10s.sh"
cp "$REPO_DIR/icons/peon-menubar.png" "$SB/peon-menubar.png"

echo "==> Installing optional double-click toggle command"
mkdir -p "$HOME/Applications"
cp "$REPO_DIR/Toggle Peon-Ping.command" "$HOME/Applications/Toggle Peon-Ping.command"
chmod +x "$HOME/Applications/Toggle Peon-Ping.command"

echo "==> Installing launch-at-login LaunchAgent"
mkdir -p "$LA_DIR"
cp "$REPO_DIR/launchagent/$LA_PLIST" "$LA_DIR/$LA_PLIST"
# Reload the agent (ignore errors if it isn't currently loaded)
launchctl bootout "gui/$(id -u)/com.peonping.swiftbar" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LA_DIR/$LA_PLIST"

echo "==> Launching SwiftBar and refreshing"
open -a SwiftBar || true
sleep 2
open "swiftbar://refreshallplugins" >/dev/null 2>&1 || true

echo "Done. The peon icon should appear in your menu bar, and SwiftBar will"
echo "now start automatically at login."
