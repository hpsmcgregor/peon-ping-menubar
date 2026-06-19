# Peon-Ping menu-bar toggle

A [SwiftBar](https://github.com/swiftbar/SwiftBar) menu-bar icon for
[peon-ping](https://github.com/PeonPing/peon-ping) that shows whether
notification sounds are on or muted, and lets you toggle them and switch voice
packs straight from the menu bar.

![the peon in the menu bar](icons/peon-menubar.png)

- **Green dot** beside the peon — sounds are **on**.
- **Red dot** — sounds are **muted** (paused).
- Click the icon for a menu: mute/unmute, pick a sound pack (grouped by
  franchise, with per-pack preview), and refresh.

It also installs a LaunchAgent so **SwiftBar starts at login**, which means the
icon survives a restart.

## Contents

| Path | What it is |
|------|------------|
| `plugins/peonping.10s.sh` | The SwiftBar plugin. Refreshes every 10s; reads peon-ping state and renders the icon + menu. |
| `icons/peon-menubar.png` | The peon menu-bar image. |
| `peonping-groups.conf` | Editable map of pack ids/globs → menu groups. |
| `launchagent/com.peonping.swiftbar.plist` | LaunchAgent that opens SwiftBar at login. |
| `Toggle Peon-Ping.command` | Optional double-click toggle for sounds (also nudges SwiftBar to refresh). |
| `install.sh` | Copies everything into place and registers the LaunchAgent. |

## Dependencies

- **macOS** (uses `launchd` and the macOS menu bar).
- **[SwiftBar](https://github.com/swiftbar/SwiftBar)** — the menu-bar host that
  runs this plugin. This is a hard dependency; the icon only appears while
  SwiftBar is running. Install it with:

  ```sh
  brew install --cask swiftbar
  ```

  Tested against SwiftBar 2.x. The `install.sh` script checks for
  `/Applications/SwiftBar.app` and aborts if it's missing.
- **[peon-ping](https://github.com/PeonPing/peon-ping)** — the tool whose sounds
  this toggles. Expected to be installed with its hook at
  `~/.claude/hooks/peon-ping/peon.sh` and config at
  `~/.claude/hooks/peon-ping/config.json`.

## Install

```sh
./install.sh
```

This will:

1. Copy `peonping.10s.sh`, `peon-menubar.png` and `peonping-groups.conf` into
   `~/Library/Application Support/SwiftBar/` (the config is only copied if you
   don't already have one, so re-installing won't overwrite your edits).
2. Copy the `Toggle Peon-Ping.command` into `~/Applications/`.
3. Install and load the LaunchAgent so SwiftBar launches at login.
4. Start SwiftBar and refresh.

## Customising the menu groups

The "Sound Pack" submenu groups packs by franchise. Those groups are **not**
hardcoded — they're driven by `peonping-groups.conf` (installed to
`~/Library/Application Support/SwiftBar/peonping-groups.conf`). Each line maps a
pack id or glob to a group label:

```
tf2_*  = Team Fortress 2     # any pack whose id starts with tf2_
peon   = Warcraft            # a single pack by id
```

- First matching line wins, so list specific ids before broad globs.
- Group order in the menu = the order groups first appear in the file.
- Packs that match nothing fall under **Other** (shown last).
- If the file is missing, packs are listed flat with no group headers — so it
  works for any pack set out of the box; the config just makes it tidier.

Edit the file and the menu updates on the next refresh (≤10s, or click
**Refresh state**).

## Uninstall

```sh
launchctl bootout "gui/$(id -u)/com.peonping.swiftbar"
rm ~/Library/LaunchAgents/com.peonping.swiftbar.plist
rm ~/Library/Application\ Support/SwiftBar/Plugins/peonping.10s.sh
rm ~/Library/Application\ Support/SwiftBar/peon-menubar.png
rm ~/Library/Application\ Support/SwiftBar/peonping-groups.conf
rm ~/Applications/Toggle\ Peon-Ping.command
```

## Notes

- SwiftBar spaces its plugin items with a little more padding than native menu
  extras, so the icon sits slightly further from its neighbour than a native
  icon would. That's a SwiftBar behaviour, not something in this plugin.
- The plugin and LaunchAgent reference paths under `$HOME`, so they work for
  any user without editing — as long as SwiftBar is at `/Applications/SwiftBar.app`.
