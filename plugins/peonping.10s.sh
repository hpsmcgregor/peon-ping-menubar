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

# Group rules live in an editable config file (peonping-groups.conf) so they're
# not baked into this script. Parse it once into parallel arrays: glob pattern
# -> group label, plus the order in which groups first appear. If the file is
# missing, no rules exist and every pack falls under "Other".
GROUPS_CONF="$HOME/Library/Application Support/SwiftBar/peonping-groups.conf"
gpat=(); glabel=(); gorder=()
if [ -f "$GROUPS_CONF" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"                                   # strip comments
    case "$line" in *=*) ;; *) continue ;; esac          # need a "pattern = label"
    pat="${line%%=*}"; lab="${line#*=}"
    pat="${pat#"${pat%%[![:space:]]*}"}"; pat="${pat%"${pat##*[![:space:]]}"}"   # trim
    lab="${lab#"${lab%%[![:space:]]*}"}"; lab="${lab%"${lab##*[![:space:]]}"}"   # trim
    [ -z "$pat" ] && continue
    gpat+=("$pat"); glabel+=("$lab")
    seen=0; for g in "${gorder[@]}"; do [ "$g" = "$lab" ] && { seen=1; break; }; done
    [ "$seen" -eq 0 ] && gorder+=("$lab")
  done < "$GROUPS_CONF"
fi

# Map a pack id to its group label via the rules (first matching pattern wins).
group_for() {
  local id="$1" i
  for i in "${!gpat[@]}"; do
    case "$id" in ${gpat[$i]}) printf '%s\n' "${glabel[$i]}"; return ;; esac
  done
  echo "Other"
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

# Print one pack's menu entry. $1=index, $2=indent prefix for the pack line
# (its actions are nested one level deeper).
print_pack() {
  local i="$1" base="$2" id="${ids[$1]}" dn="${names[$1]}" smp="${samples[$1]}"
  if [ "$id" = "$current_pack" ]; then echo "${base}${dn} | checked=true"; else echo "${base}${dn}"; fi
  echo "${base}--Use this pack | bash=\"$PEON\" param1=packs param2=use param3=${id} terminal=false refresh=true sfimage=checkmark.circle"
  [ -n "$smp" ] && echo "${base}--▶ Preview | bash=/usr/bin/afplay param1=\"$smp\" terminal=false sfimage=play.circle"
}

# Groups to display, in config order, with any "Other" packs last.
present=()
for g in "${gorder[@]}"; do
  for i in "${!ids[@]}"; do [ "${groups[$i]}" = "$g" ] && { present+=("$g"); break; }; done
done
for i in "${!ids[@]}"; do [ "${groups[$i]}" = "Other" ] && { present+=("Other"); break; }; done

if [ "${#present[@]}" -le 1 ]; then
  # No grouping in play -> flat list, no headers.
  for i in "${!ids[@]}"; do print_pack "$i" "--"; done
else
  for grp in "${present[@]}"; do
    echo "--${grp}"
    for i in "${!ids[@]}"; do
      [ "${groups[$i]}" = "$grp" ] || continue
      print_pack "$i" "----"
    done
  done
fi

echo "---"
echo "Refresh state | refresh=true sfimage=arrow.clockwise"
