#!/usr/bin/env bash
# Configure zellij status bar: machine icon, timezone
# Usage:
#   configure.sh icon                           # random icon + color, auto hostname
#   configure.sh icon --pick                    # interactive fuzzy picker (requires fzf)
#   configure.sh icon --custom "󰄛" --color 3    # any nerd font glyph
#   configure.sh icon --name "my-box"           # set display name (combinable)
#   configure.sh timezone                       # interactive timezone picker
#   configure.sh timezone America/New_York      # set timezone directly

set -euo pipefail

ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
CONFIG_FILE="$ZELLIJ_CONFIG_DIR/machine-id.conf"
LAYOUT_FILE="$ZELLIJ_CONFIG_DIR/layouts/default.kdl"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Locate icons.tsv (same directory as this script, or config dir)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ICONS_FILE="$SCRIPT_DIR/icons.tsv"
if [[ ! -f "$ICONS_FILE" ]]; then
  ICONS_FILE="$ZELLIJ_CONFIG_DIR/icons.tsv"
fi

# Catppuccin Mocha accent colors (hex + true color RGB for terminal preview)
COLORS=(    "#F5C2E7" "#CBA6F7" "#B4BEFE" "#89B4FA" "#94E2D5" "#A6E3A1" "#F9E2AF" "#FAB387" "#F38BA8")
COLOR_NAMES=("pink"    "mauve"   "lavender" "blue"   "teal"    "green"   "yellow"  "peach"   "red")
COLOR_RGB=(  "245;194;231" "203;166;247" "180;190;254" "137;180;250" "148;226;213" "166;227;161" "249;226;175" "250;179;135" "243;139;168")

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

auto_hostname() {
  if [ -f /etc/bootstrap-hostname ]; then
    cat /etc/bootstrap-hostname
  else
    hostname
  fi
}

detect_timezone() {
  if [[ -n "${TZ:-}" && "${TZ:-}" != "UTC" && "${TZ:-}" != "Etc/UTC" ]]; then
    echo "$TZ"
  elif [[ -f /etc/timezone ]] && [[ "$(cat /etc/timezone)" != "Etc/UTC" && "$(cat /etc/timezone)" != "UTC" ]]; then
    cat /etc/timezone
  elif command -v timedatectl >/dev/null 2>&1; then
    local tz
    tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "")
    if [[ -n "$tz" && "$tz" != "UTC" && "$tz" != "Etc/UTC" ]]; then
      echo "$tz"
    else
      echo "UTC"
    fi
  else
    echo "UTC"
  fi
}

detect_timezone_by_ip() {
  if command -v curl >/dev/null 2>&1; then
    curl -s --max-time 3 ipinfo.io/timezone 2>/dev/null || echo ""
  else
    echo ""
  fi
}

current_layout_timezone() {
  if [[ -f "$LAYOUT_FILE" ]]; then
    grep -oP 'datetime_timezone "\K[^"]+' "$LAYOUT_FILE" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

# --------------------------------------------------------------------------
# Icon subcommand
# --------------------------------------------------------------------------

icon_pick_random() {
  if [[ ! -f "$ICONS_FILE" ]]; then
    echo "Error: icons.tsv not found" >&2; exit 1
  fi
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

icon_save() {
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

icon_pick_color() {
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

icon_pick_name() {
  echo ""
  local default_name
  default_name=$(auto_hostname)
  read -rp "Display name [$default_name]: " name_input
  CHOSEN_NAME="${name_input:-$default_name}"
}

icon_interactive() {
  if [[ ! -f "$ICONS_FILE" ]]; then
    echo "Error: icons.tsv not found" >&2; exit 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required for interactive picker" >&2
    exit 1
  fi

  local selection
  selection=$(awk -F'\t' '{printf "%s  %s\n", $1, $2}' "$ICONS_FILE" | \
    fzf --ansi --layout=reverse --height=20 \
      --prompt="Icon> " --pointer="▶" \
      --header="Type to search (e.g. phone, tree, rocket) or Esc for custom" \
      --header-first) || {
    echo ""
    read -rp "Paste a custom nerd font glyph: " custom_glyph
    if [[ -z "$custom_glyph" ]]; then
      echo "Cancelled." >&2; exit 1
    fi
    CHOSEN_ICON="$custom_glyph"
    CHOSEN_ICON_NAME="custom"
    icon_pick_color
    icon_pick_name
    return
  }

  CHOSEN_ICON="${selection%%  *}"
  CHOSEN_ICON_NAME="${selection#*  }"

  icon_pick_color
  icon_pick_name
}

cmd_icon() {
  local mode="pick"
  local color_idx=""
  local custom_icon=""
  CHOSEN_NAME=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --random)  mode="random"; shift ;;
      --color)   color_idx="$2"; shift 2 ;;
      --custom)  custom_icon="$2"; shift 2 ;;
      --name)    CHOSEN_NAME="$2"; shift 2 ;;
      *)         echo "Unknown icon option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -n "$custom_icon" ]]; then
    CHOSEN_ICON="$custom_icon"
    CHOSEN_ICON_NAME="custom"
    CHOSEN_COLOR_IDX=$((${color_idx:-$((RANDOM % ${#COLORS[@]} + 1))} - 1))
    CHOSEN_COLOR="${COLORS[$CHOSEN_COLOR_IDX]}"
    CHOSEN_COLOR_NAME="${COLOR_NAMES[$CHOSEN_COLOR_IDX]}"
    mode="custom"
  fi

  case "$mode" in
    random) icon_pick_random ;;
    pick)   icon_interactive ;;
    custom) ;; # already set above
  esac

  icon_save
}

# --------------------------------------------------------------------------
# Timezone subcommand
# --------------------------------------------------------------------------

cmd_timezone() {
  local tz="${1:-}"

  if [[ "$tz" == "auto" ]]; then
    tz=$(detect_timezone)
    if [[ "$tz" == "UTC" ]]; then
      echo "    System timezone is UTC, trying IP geolocation..."
      tz=$(detect_timezone_by_ip)
      if [[ -z "$tz" ]]; then
        echo "    Could not detect timezone" >&2
        exit 1
      fi
    fi
    echo "    Auto-detected: $tz"
  fi

  if [[ -z "$tz" ]]; then
    local current detected
    current=$(current_layout_timezone)
    detected=$(detect_timezone)
    echo "    Current: $current | Detected: $detected"

    local zidir="${TZDIR:-/usr/share/zoneinfo}"
    if command -v fzf >/dev/null 2>&1 && [[ -d "$zidir" ]]; then
      # Build timezone list from zoneinfo
      local tz_list
      tz_list=$(find "$zidir" -type f -not -path '*/posix/*' -not -path '*/right/*' \
        | sed "s|$zidir/||" | grep '/' | sort)
      tz=$(printf '%s\n' "$tz_list" | \
        fzf --layout=reverse --height=20 \
          --prompt="Timezone> " --pointer="▶" \
          --query="$detected" \
          --header="Type to search (e.g. Tokyo, New_York, London)" \
          --header-first) || { echo "Cancelled." >&2; exit 1; }
    else
      echo ""
      read -rp "Timezone [$detected]: " tz_input
      tz="${tz_input:-$detected}"
    fi
  fi

  # Validate: check if zoneinfo exists
  local zidir="${TZDIR:-/usr/share/zoneinfo}"
  if [[ ! -f "$zidir/$tz" ]] && [[ "$tz" != "UTC" ]]; then
    echo "Warning: $zidir/$tz not found, using anyway" >&2
  fi

  if [[ ! -f "$LAYOUT_FILE" ]]; then
    echo "Error: layout file not found at $LAYOUT_FILE" >&2
    exit 1
  fi

  # Update the layout file
  sed -i "s|datetime_timezone \"[^\"]*\"|datetime_timezone \"$tz\"|" "$LAYOUT_FILE"
  echo "    Timezone set to: $tz"
  echo "    Restart zellij session to apply"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
  echo "Usage: zjbar <command> [options]"
  echo ""
  echo "Commands:"
  echo "  icon                  Interactive fuzzy icon picker"
  echo "  icon --random         Random icon + color (used by install)"
  echo "  icon --custom GLYPH  Set a specific nerd font glyph"
  echo "  timezone              Interactive timezone picker"
  echo "  timezone auto         Auto-detect (system, then IP geolocation)"
  echo "  timezone ZONE         Set timezone directly (e.g. America/New_York)"
  exit 0
fi

COMMAND="$1"; shift
case "$COMMAND" in
  icon)     cmd_icon "$@" ;;
  timezone) cmd_timezone "$@" ;;
  *)        echo "Unknown command: $COMMAND" >&2; exit 1 ;;
esac
