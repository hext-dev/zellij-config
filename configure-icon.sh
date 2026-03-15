#!/usr/bin/env bash
# Configure machine identity for zellij status bar (icon, color, display name)
# Usage:
#   configure-icon.sh                          # random icon + color, auto hostname
#   configure-icon.sh --pick                   # interactive picker
#   configure-icon.sh --icon 3 --color 2       # set by index, auto hostname
#   configure-icon.sh --name "my-box"          # set display name (combinable)

set -euo pipefail

CONFIG_FILE="$HOME/.config/zellij/machine-id.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Nerd Font animal icons — FA + MDI range
ICONS=(
  $'\uf17c'           # penguin (tux)
  $'\uf1b0'           # paw print
  $'\uf188'           # bug
  $'\U000f0150'       # cat
  $'\U000f0a43'       # dog
  $'\U000f023a'       # fish
  $'\U000f0317'       # owl
  $'\U000f0ae2'       # turtle
  $'\U000f011b'       # bee
  $'\U000f057a'       # snail
  $'\U000f15c6'       # duck
  $'\U000f1503'       # rabbit
  $'\U000f1386'       # butterfly
  $'\U000f0e84'       # snake
  $'\U000f0672'       # spider
  $'\U000f1302'       # bat
)
ICON_NAMES=(
  "penguin" "paw" "bug" "cat" "dog" "fish" "owl" "turtle"
  "bee" "snail" "duck" "rabbit" "butterfly" "snake" "spider" "bat"
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
  echo "Available icons:"
  for i in "${!ICONS[@]}"; do
    printf "  %2d) %s  %s\n" "$((i+1))" "${ICONS[$i]}" "${ICON_NAMES[$i]}"
  done
  echo ""
  read -rp "Pick icon [1-${#ICONS[@]}]: " icon_choice
  CHOSEN_ICON_IDX=$((icon_choice - 1))
  if [[ $CHOSEN_ICON_IDX -lt 0 || $CHOSEN_ICON_IDX -ge ${#ICONS[@]} ]]; then
    echo "Invalid choice" >&2; exit 1
  fi

  echo ""
  echo "Available colors:"
  for i in "${!COLORS[@]}"; do
    printf "  %2d) %s  %s\n" "$((i+1))" "${COLORS[$i]}" "${COLOR_NAMES[$i]}"
  done
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

  CHOSEN_ICON="${ICONS[$CHOSEN_ICON_IDX]}"
  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
  CHOSEN_ICON_NAME="${ICON_NAMES[$CHOSEN_ICON_IDX]}"
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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pick)   MODE="pick"; shift ;;
    --icon)   ICON_IDX="$2"; shift 2 ;;
    --color)  COLOR_IDX="$2"; shift 2 ;;
    --name)   CHOSEN_NAME="$2"; shift 2 ;;
    *)        echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$ICON_IDX" && -n "$COLOR_IDX" ]]; then
  MODE="index"
fi

case "$MODE" in
  random) pick_random ;;
  pick)   interactive_pick ;;
  index)  set_by_index ;;
esac

save_config
