#!/usr/bin/env bash
# Configure machine identity for zellij status bar (icon, color, display name)
# Usage:
#   configure-icon.sh                          # random icon + color, auto hostname
#   configure-icon.sh --pick                   # interactive picker
#   configure-icon.sh --icon 3 --color 2       # set by index, auto hostname
#   configure-icon.sh --custom "󰄛" --color 3   # any nerd font glyph
#   configure-icon.sh --name "my-box"          # set display name (combinable)

set -euo pipefail

CONFIG_FILE="$HOME/.config/zellij/machine-id.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"

# 128 Nerd Font icons — verified codepoints from nerdfonts.com cheat sheet
# Animals (1-24)
ICONS=(
  $'\U000F011B'       # cat
  $'\U000F0A43'       # dog
  $'\U000F023A'       # fish
  $'\U000F00E4'       # bug
  $'\U000F11EA'       # spider
  $'\U000F0EC0'       # penguin
  $'\U000F033D'       # linux
  $'\U000F03E9'       # paw
  $'\U000F0CD7'       # turtle
  $'\U000F150E'       # snake
  $'\U000F18B4'       # dolphin
  $'\U000F07C6'       # elephant
  $'\U000F15BF'       # horse
  $'\U000F0907'       # rabbit
  $'\U000F01E5'       # duck
  $'\U000F03D2'       # owl
  $'\U000F0B5F'       # bat
  $'\U000F0FA1'       # bee
  $'\U000F1589'       # butterfly
  $'\U000F15C6'       # bird
  $'\U000F1677'       # snail
  $'\U000F0F01'       # jellyfish
  $'\U000F1327'       # rodent
  $'\uEEF8'           # dragon
  # Nature (25-42)
  $'\U000F0531'       # tree
  $'\U000F0405'       # pine-tree
  $'\U000F024A'       # flower
  $'\U000F032A'       # leaf
  $'\U000F0DB5'       # cactus
  $'\U000F07DF'       # mushroom
  $'\U000F0816'       # clover
  $'\U000F1055'       # palm-tree
  $'\U000F0E66'       # sprout
  $'\U000F1897'       # forest
  $'\U000F0717'       # snowflake
  $'\U000F0599'       # sun
  $'\U000F0F65'       # moon
  $'\U000F058C'       # water
  $'\U000F078D'       # waves
  $'\U000F0238'       # fire
  $'\U000F140B'       # lightning
  $'\uEE46'           # earth
  # Space (43-54)
  $'\U000F0471'       # satellite
  $'\U000F0463'       # rocket
  $'\U000F14DE'       # rocket-launch
  $'\U000F10C4'       # ufo
  $'\U000F04CE'       # star
  $'\U000F1741'       # shooting-star
  $'\U000F0B4E'       # telescope
  $'\U000F0018'       # orbit
  $'\U000F0768'       # atom
  $'\U000F018B'       # compass
  $'\U000F00A5'       # binoculars
  $'\uEE45'           # planet
  # Objects (55-78)
  $'\U000F0031'       # anchor
  $'\U000F04E5'       # sword
  $'\U000F08C8'       # axe
  $'\U000F0498'       # shield
  $'\U000F0306'       # key
  $'\U000F033E'       # lock
  $'\U000F01A5'       # crown
  $'\U000F023B'       # flag
  $'\U000F009A'       # bell
  $'\U000F04AA'       # sitemap
  $'\U000F08EA'       # hammer
  $'\U000F05B7'       # wrench
  $'\U000F0B2F'       # crystal-ball
  $'\U000F01C8'       # gem
  $'\U000F05E2'       # candle
  $'\U000F0691'       # bomb
  $'\U000F10CF'       # boomerang
  $'\U000F04FE'       # target
  $'\U000F0431'       # puzzle
  $'\U000F0538'       # trophy
  $'\U000F0987'       # medal
  $'\U000F076E'       # dice
  $'\U000F0EDD'       # campfire
  $'\U000F05DD'       # bullseye
  # Tech (79-102)
  $'\uF120'           # terminal
  $'\U000F0169'       # code-braces
  $'\U000F048B'       # server
  $'\U000F015F'       # cloud
  $'\U000F01BC'       # database
  $'\U000F0493'       # cog
  $'\U000F08D6'       # cogs
  $'\U000F0EE0'       # cpu
  $'\U000F01EE'       # email
  $'\uF1D8'           # paper-plane
  $'\U000F030C'       # keyboard
  $'\U000F0379'       # monitor
  $'\U000F01C4'       # desktop
  $'\U000F0322'       # laptop
  $'\U000F0297'       # gamepad
  $'\U000F02CB'       # headphones
  $'\U000F0100'       # camera
  $'\U000F0567'       # video
  $'\U000F06A5'       # power-plug
  $'\U000F0335'       # lightbulb
  $'\U000F06A9'       # robot
  $'\U000F061A'       # chip
  $'\U000F0437'       # radar
  $'\uEF60'           # satellite-dish
  # Symbols (103-128)
  $'\U000F02D1'       # heart
  $'\U000F0208'       # eye
  $'\U000F05F6'       # heartbeat
  $'\U000F0124'       # certificate
  $'\uF111'           # circle
  $'\U000F0B8A'       # diamond
  $'\U000F01A6'       # cube
  $'\U000F06E4'       # infinity
  $'\U000F02A0'       # ghost
  $'\U000F1477'       # wizard-hat
  $'\U000F13B6'       # virus
  $'\U000F06D3'       # feather
  $'\U000F0093'       # flask
  $'\U000F0237'       # fingerprint
  $'\U000F0D02'       # drama-masks
  $'\U000F0680'       # yin-yang
  $'\uF255'           # fist
  $'\U000F0E44'       # gift
  $'\U000F0F2E'       # wave
  $'\U000F068C'       # skull
  $'\uEF08'           # mountain
  $'\U000F0884'       # peace
  $'\U000F0780'       # shield-half
  $'\U000F0093'       # flask-alt
  $'\U000F04CE'       # star-alt
  $'\U000F009A'       # bell-alt
)
ICON_NAMES=(
  # Animals
  "cat" "dog" "fish" "bug" "spider" "penguin" "linux" "paw"
  "turtle" "snake" "dolphin" "elephant" "horse" "rabbit" "duck" "owl"
  "bat" "bee" "butterfly" "bird" "snail" "jellyfish" "rodent" "dragon"
  # Nature
  "tree" "pine-tree" "flower" "leaf" "cactus" "mushroom" "clover" "palm-tree"
  "sprout" "forest" "snowflake" "sun" "moon" "water" "waves" "fire"
  "lightning" "earth"
  # Space
  "satellite" "rocket" "rocket-launch" "ufo" "star" "shooting-star" "telescope" "orbit"
  "atom" "compass" "binoculars" "planet"
  # Objects
  "anchor" "sword" "axe" "shield" "key" "lock" "crown" "flag"
  "bell" "sitemap" "hammer" "wrench" "crystal-ball" "gem" "candle" "bomb"
  "boomerang" "target" "puzzle" "trophy" "medal" "dice" "campfire" "bullseye"
  # Tech
  "terminal" "code-braces" "server" "cloud" "database" "cog" "cogs" "cpu"
  "email" "paper-plane" "keyboard" "monitor" "desktop" "laptop" "gamepad" "headphones"
  "camera" "video" "power-plug" "lightbulb" "robot" "chip" "radar" "satellite-dish"
  # Symbols
  "heart" "eye" "heartbeat" "certificate" "circle" "diamond" "cube" "infinity"
  "ghost" "wizard-hat" "virus" "feather" "flask" "fingerprint" "drama-masks" "yin-yang"
  "fist" "gift" "wave" "skull" "mountain" "peace" "shield-half" "flask-alt"
  "star-alt" "bell-alt"
)

# Catppuccin Mocha accent colors
COLORS=(
  "#F5C2E7"   # pink
  "#CBA6F7"   # mauve
  "#B4BEFE"   # lavender
  "#89B4FA"   # blue
  "#94E2D5"   # teal
  "#A6E3A1"   # green
  "#F9E2AF"   # yellow
  "#FAB387"   # peach
  "#F38BA8"   # red
)
COLOR_NAMES=(
  "pink" "mauve" "lavender" "blue" "teal" "green" "yellow" "peach" "red"
)

# ANSI 256-color approximations for terminal preview
COLOR_ANSI=(
  "213"   # pink
  "141"   # mauve
  "147"   # lavender
  "111"   # blue
  "116"   # teal
  "151"   # green
  "223"   # yellow
  "216"   # peach
  "211"   # red
)

COLS=8  # icons per row in picker

auto_hostname() {
  if [ -f /etc/bootstrap-hostname ]; then
    cat /etc/bootstrap-hostname
  else
    hostname
  fi
}

pick_random() {
  CHOSEN_ICON_IDX=$((RANDOM % ${#ICONS[@]}))
  CHOSEN_COLOR_IDX=$((RANDOM % ${#COLORS[@]}))
  CHOSEN_ICON="${ICONS[$CHOSEN_ICON_IDX]}"
  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
  CHOSEN_ICON_NAME="${ICON_NAMES[$CHOSEN_ICON_IDX]}"
  CHOSEN_COLOR_NAME="${COLOR_NAMES[$CHOSEN_COLOR_IDX]}"
}

save_config() {
  local name="${CHOSEN_NAME:-$(auto_hostname)}"
  [ ${#name} -gt 14 ] && name="${name:0:14}…"
  cat > "$CONFIG_FILE" << EOF
ICON=$CHOSEN_ICON
COLOR=$CHOSEN_COLOR
NAME=$name
EOF
  echo "    Machine ID: $CHOSEN_ICON  $name ($CHOSEN_ICON_NAME, $CHOSEN_COLOR_NAME)"
}

interactive_pick() {
  local total=${#ICONS[@]}
  local rows=$(( (total + COLS - 1) / COLS ))

  # Show icons in a grid, each column in a different color for visual variety
  echo "Icons (or enter 'c' to paste a custom nerd font glyph):"
  for r in $(seq 0 $((rows - 1))); do
    for c in $(seq 0 $((COLS - 1))); do
      local idx=$((r * COLS + c))
      if [[ $idx -lt $total ]]; then
        local ansi_idx=$((c % ${#COLOR_ANSI[@]}))
        printf "  \033[38;5;%sm%3d) %s\033[0m" "${COLOR_ANSI[$ansi_idx]}" "$((idx+1))" "${ICONS[$idx]}"
      fi
    done
    echo ""
  done
  echo ""
  read -rp "Pick icon [1-${total}] or 'c' for custom: " icon_input

  if [[ "$icon_input" == "c" ]]; then
    read -rp "Paste nerd font glyph: " custom_glyph
    if [[ -z "$custom_glyph" ]]; then
      echo "No glyph provided" >&2; exit 1
    fi
    CHOSEN_ICON="$custom_glyph"
    CHOSEN_ICON_NAME="custom"
    CHOSEN_ICON_IDX=-1
  else
    CHOSEN_ICON_IDX=$((icon_input - 1))
    if [[ $CHOSEN_ICON_IDX -lt 0 || $CHOSEN_ICON_IDX -ge $total ]]; then
      echo "Invalid choice" >&2; exit 1
    fi
    CHOSEN_ICON="${ICONS[$CHOSEN_ICON_IDX]}"
    CHOSEN_ICON_NAME="${ICON_NAMES[$CHOSEN_ICON_IDX]}"
  fi

  echo ""
  echo "Colors:"
  for i in "${!COLORS[@]}"; do
    printf "  \033[38;5;%sm%d) %-10s ●\033[0m" "${COLOR_ANSI[$i]}" "$((i+1))" "${COLOR_NAMES[$i]}"
    [[ $(( (i+1) % 3 )) -eq 0 ]] && echo ""
  done
  echo ""
  echo ""
  read -rp "Pick color [1-${#COLORS[@]}]: " color_choice
  CHOSEN_COLOR_IDX=$((color_choice - 1))
  if [[ $CHOSEN_COLOR_IDX -lt 0 || $CHOSEN_COLOR_IDX -ge ${#COLORS[@]} ]]; then
    echo "Invalid choice" >&2; exit 1
  fi

  echo ""
  local default_name
  default_name=$(auto_hostname)
  read -rp "Display name [$default_name]: " name_input
  CHOSEN_NAME="${name_input:-$default_name}"

  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
  CHOSEN_COLOR_NAME="${COLOR_NAMES[$CHOSEN_COLOR_IDX]}"
}

set_by_index() {
  local icon_idx=$((ICON_IDX - 1))
  local color_idx=$((COLOR_IDX - 1))
  if [[ $icon_idx -lt 0 || $icon_idx -ge ${#ICONS[@]} ]]; then
    echo "Icon index out of range [1-${#ICONS[@]}]" >&2; exit 1
  fi
  if [[ $color_idx -lt 0 || $color_idx -ge ${#COLORS[@]} ]]; then
    echo "Color index out of range [1-${#COLORS[@]}]" >&2; exit 1
  fi
  CHOSEN_ICON="${ICONS[$icon_idx]}"
  CHOSEN_COLOR="${COLORS[$color_idx]}"
  CHOSEN_ICON_NAME="${ICON_NAMES[$icon_idx]}"
  CHOSEN_COLOR_NAME="${COLOR_NAMES[$color_idx]}"
}

# Parse args
MODE="random"
ICON_IDX=""
COLOR_IDX=""
CHOSEN_NAME=""
CUSTOM_ICON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pick)    MODE="pick"; shift ;;
    --icon)    ICON_IDX="$2"; shift 2 ;;
    --color)   COLOR_IDX="$2"; shift 2 ;;
    --custom)  CUSTOM_ICON="$2"; shift 2 ;;
    --name)    CHOSEN_NAME="$2"; shift 2 ;;
    *)         echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$CUSTOM_ICON" ]]; then
  CHOSEN_ICON="$CUSTOM_ICON"
  CHOSEN_ICON_NAME="custom"
  CHOSEN_COLOR_IDX=$((${COLOR_IDX:-$((RANDOM % ${#COLORS[@]} + 1))} - 1))
  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
  CHOSEN_COLOR_NAME="${COLOR_NAMES[$CHOSEN_COLOR_IDX]}"
elif [[ -n "$ICON_IDX" && -n "$COLOR_IDX" ]]; then
  MODE="index"
fi

case "$MODE" in
  random) [[ -z "$CUSTOM_ICON" ]] && pick_random ;;
  pick)   interactive_pick ;;
  index)  set_by_index ;;
esac

save_config
