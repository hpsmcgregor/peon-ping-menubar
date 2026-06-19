#!/bin/bash
# <xbar.title>Peon-Ping Toggle</xbar.title>
# <xbar.desc>Shows peon-ping sound state in the menu bar and toggles it on click.</xbar.desc>
# <xbar.author>Claude Code</xbar.author>
# <swiftbar.runInBash>true</swiftbar.runInBash>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

PEON="$HOME/.claude/hooks/peon-ping/peon.sh"
CFG="$HOME/.claude/hooks/peon-ping/config.json"
PAUSED="$HOME/.claude/hooks/peon-ping/.paused"
ICON="$HOME/Library/Application Support/SwiftBar/peon-menubar.png"

# Peon icon as the menu-bar image (base64); state shown by a coloured dot beside it.
B64="$(base64 < "$ICON" 2>/dev/null | tr -d '\n')"

# Sounds are active only if the master switch is on AND no .paused marker exists.
# `peon.sh toggle` adds/removes the .paused marker (it does NOT change "enabled").
enabled="$(/usr/bin/plutil -extract enabled raw -o - "$CFG" 2>/dev/null)"

if [ "$enabled" = "true" ] && [ ! -f "$PAUSED" ]; then
  # Menu bar: peon icon + green dot
  echo "● | image=$B64 color=#34c759 size=12"
  echo "---"
  echo "Peon-Ping is ON | sfimage=speaker.wave.2.fill"
  echo "Mute (pause sounds) | bash=\"$PEON\" param1=toggle terminal=false refresh=true sfimage=speaker.slash.fill"
else
  # Menu bar: peon icon + red dot
  echo "● | image=$B64 color=#ff3b30 size=12"
  echo "---"
  echo "Peon-Ping is OFF | sfimage=speaker.slash.fill"
  echo "Unmute (resume sounds) | bash=\"$PEON\" param1=toggle terminal=false refresh=true sfimage=speaker.wave.2.fill"
fi

echo "---"
# --- Sound pack switcher (grouped, friendly names, per-pack preview) ---
PACKS_DIR="$HOME/.openpeon/packs"
current_pack="$(/usr/bin/plutil -extract default_pack raw -o - "$CFG" 2>/dev/null)"

# Map a pack id to a franchise/group label.
group_for() {
  case "$1" in
    tf2_*)                                            echo "Team Fortress 2" ;;
    ccg_*|ra2_*|tiberian-sun-*)                       echo "Command & Conquer" ;;
    sc_*)                                             echo "StarCraft" ;;
    caliph|pig|rat|richard|saladin|snake|sultan|wolf) echo "Stronghold Crusader" ;;
    peon|peasant)                                     echo "Warcraft" ;;
    aoe2|glados|sheogorath|halo3_announcer|hd2_helldiver|worms-armageddon) echo "Games" ;;
    airplane|hal_2001|mr_meeseeks|rocky|super_troopers|tropic-thunder) echo "Movies & TV" ;;
    *)                                                echo "Other" ;;
  esac
}

# Gather pack metadata once.
ids=(); names=(); groups=(); samples=(); current_display="$current_pack"
if [ -d "$PACKS_DIR" ]; then
  for p in "$PACKS_DIR"/*/; do
    id="$(basename "$p")"; [ "$id" = "*" ] && continue
    [ -f "${p}openpeon.json" ] || continue
    dn="$(sed -n 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${p}openpeon.json" | head -1)"
    [ -z "$dn" ] && dn="$id"
    smp="$(find "${p}sounds" -type f \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.m4a' -o -iname '*.aac' -o -iname '*.aiff' -o -iname '*.caf' \) 2>/dev/null | head -1)"
    ids+=("$id"); names+=("$dn"); groups+=("$(group_for "$id")"); samples+=("$smp")
    [ "$id" = "$current_pack" ] && current_display="$dn"
  done
fi

echo "Sound Pack: ${current_display} | sfimage=music.note.list"
for grp in "Team Fortress 2" "Command & Conquer" "StarCraft" "Stronghold Crusader" "Warcraft" "Games" "Movies & TV" "Other"; do
  any=0; for i in "${!ids[@]}"; do [ "${groups[$i]}" = "$grp" ] && { any=1; break; }; done
  [ "$any" = 0 ] && continue
  echo "--${grp}"
  for i in "${!ids[@]}"; do
    [ "${groups[$i]}" = "$grp" ] || continue
    id="${ids[$i]}"; dn="${names[$i]}"; smp="${samples[$i]}"
    if [ "$id" = "$current_pack" ]; then
      echo "----${dn} | checked=true"
    else
      echo "----${dn}"
    fi
    echo "------Use this pack | bash=\"$PEON\" param1=packs param2=use param3=${id} terminal=false refresh=true sfimage=checkmark.circle"
    [ -n "$smp" ] && echo "------▶ Preview | bash=/usr/bin/afplay param1=\"$smp\" terminal=false sfimage=play.circle"
  done
done

echo "---"
echo "Refresh state | refresh=true sfimage=arrow.clockwise"
