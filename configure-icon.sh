#!/usr/bin/env bash
# Configure machine identity for zellij status bar (icon, color, display name)
# Usage:
#   configure-icon.sh                          # random icon + color, auto hostname
#   configure-icon.sh --pick                   # interactive fuzzy picker (requires fzf)
#   configure-icon.sh --custom "󰄛" --color 3   # any nerd font glyph
#   configure-icon.sh --name "my-box"          # set display name (combinable)

set -euo pipefail

CONFIG_FILE="$HOME/.config/zellij/machine-id.conf"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Locate icons.tsv (same directory as this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ICONS_FILE="$SCRIPT_DIR/icons.tsv"
if [[ ! -f "$ICONS_FILE" ]]; then
  # Fall back to ~/.config/zellij/icons.tsv (install.sh copies it there)
  ICONS_FILE="$HOME/.config/zellij/icons.tsv"
fi
if [[ ! -f "$ICONS_FILE" ]]; then
  echo "Error: icons.tsv not found" >&2
  exit 1
fi

# Catppuccin Mocha accent colors (hex + true color RGB for terminal preview)
COLORS=(    "#F5C2E7" "#CBA6F7" "#B4BEFE" "#89B4FA" "#94E2D5" "#A6E3A1" "#F9E2AF" "#FAB387" "#F38BA8")
COLOR_NAMES=("pink"    "mauve"   "lavender" "blue"   "teal"    "green"   "yellow"  "peach"   "red")
COLOR_RGB=(  "245;194;231" "203;166;247" "180;190;254" "137;180;250" "148;226;213" "166;227;161" "249;226;175" "250;179;135" "243;139;168")

auto_hostname() {
  if [ -f /etc/bootstrap-hostname ]; then
    cat /etc/bootstrap-hostname
  else
    hostname
  fi
}

pick_random() {
  local total
  total=$(wc -l < "$ICONS_FILE")
  local line_num=$(( RANDOM % total + 1 ))
  local line
  line=$(sed -n "${line_num}p" "$ICONS_FILE")
  CHOSEN_ICON=$(printf '%s' "$line" | cut -f1)
  CHOSEN_ICON_NAME=$(printf '%s' "$line" | cut -f2)
  CHOSEN_COLOR_IDX=$((RANDOM % ${#COLORS[@]}))
  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
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
  printf "    Machine ID: \033[38;2;%sm%s  %s\033[0m (%s, %s)\n" \
    "${COLOR_RGB[$CHOSEN_COLOR_IDX]}" "$CHOSEN_ICON" "$name" "$CHOSEN_ICON_NAME" "$CHOSEN_COLOR_NAME"
}

pick_color() {
  echo ""
  echo "Colors:"
  for i in "${!COLORS[@]}"; do
    printf "  \033[38;2;%sm%d) %-10s ●\033[0m" "${COLOR_RGB[$i]}" "$((i+1))" "${COLOR_NAMES[$i]}"
    [[ $(( (i+1) % 3 )) -eq 0 ]] && echo ""
  done
  echo ""
  echo ""
  read -rp "Pick color [1-${#COLORS[@]}]: " color_choice
  CHOSEN_COLOR_IDX=$((color_choice - 1))
  if [[ $CHOSEN_COLOR_IDX -lt 0 || $CHOSEN_COLOR_IDX -ge ${#COLORS[@]} ]]; then
    echo "Invalid choice" >&2; exit 1
  fi
  CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
  CHOSEN_COLOR_NAME="${COLOR_NAMES[$CHOSEN_COLOR_IDX]}"
}

pick_name() {
  echo ""
  local default_name
  default_name=$(auto_hostname)
  read -rp "Display name [$default_name]: " name_input
  CHOSEN_NAME="${name_input:-$default_name}"
}

interactive_pick() {
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required for interactive picker" >&2
    exit 1
  fi

  # fzf over icons.tsv — each line is "GLYPH\tname", display as "GLYPH  name"
  local selection
  selection=$(awk -F'\t' '{printf "%s  %s\n", $1, $2}' "$ICONS_FILE" | \
    fzf --ansi --layout=reverse --height=20 \
      --prompt="Icon> " --pointer="▶" \
      --header="Type to search (e.g. phone, tree, rocket) or Esc for custom" \
      --header-first) || {
    # User pressed Esc — offer custom glyph entry
    echo ""
    read -rp "Paste a custom nerd font glyph: " custom_glyph
    if [[ -z "$custom_glyph" ]]; then
      echo "Cancelled." >&2; exit 1
    fi
    CHOSEN_ICON="$custom_glyph"
    CHOSEN_ICON_NAME="custom"
    pick_color
    pick_name
    return
  }

  CHOSEN_ICON="${selection%%  *}"
  CHOSEN_ICON_NAME="${selection#*  }"

  pick_color
  pick_name
}

# Parse args
MODE="random"
COLOR_IDX=""
CHOSEN_NAME=""
CUSTOM_ICON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pick)    MODE="pick"; shift ;;
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
fi

case "$MODE" in
  random) [[ -z "$CUSTOM_ICON" ]] && pick_random ;;
  pick)   interactive_pick ;;
esac

save_config
