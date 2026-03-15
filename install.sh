#!/usr/bin/env bash
# Zellij config installer
# Copies config files and downloads zjstatus plugin
#
# Usage:
#   ./install.sh          (from a clone)
#   ./install.sh --force  (re-download zjstatus even if present)
#   curl -fsSL https://raw.githubusercontent.com/hext-dev/zellij-config/<hash>/install.sh | bash
#
set -euo pipefail

ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"
ZELLIJ_CACHE_DIR="$HOME/.cache/zellij"
ZELLIJ_CONFIG_REPO="https://github.com/hext-dev/zellij-config.git"
ZELLIJ_CONFIG_CACHE="$HOME/.local/share/zellij-config"
FORCE=false
CLONED_TEMP=false

[[ "${1:-}" == "--force" ]] && FORCE=true

# Determine repo root — either we're running from a clone, or we need to fetch one
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.kdl" ]]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running via curl-pipe or from outside the repo — clone to cache
  if [ -d "$ZELLIJ_CONFIG_CACHE/.git" ]; then
    git -C "$ZELLIJ_CONFIG_CACHE" pull --ff-only -q 2>/dev/null || true
  else
    git clone -q "$ZELLIJ_CONFIG_REPO" "$ZELLIJ_CONFIG_CACHE"
  fi
  REPO_DIR="$ZELLIJ_CONFIG_CACHE"
  CLONED_TEMP=true
fi

if [[ ! -f "$REPO_DIR/config.kdl" ]] || [[ ! -f "$REPO_DIR/zjstatus-version" ]]; then
  echo "Error: config.kdl or zjstatus-version not found in $REPO_DIR" >&2
  exit 1
fi

ZJSTATUS_VERSION=$(tr -d '[:space:]' < "$REPO_DIR/zjstatus-version")

echo "==> Installing zellij config"

# Create directory structure
mkdir -p "$ZELLIJ_CONFIG_DIR/layouts" "$ZELLIJ_CONFIG_DIR/themes" "$ZELLIJ_CONFIG_DIR/plugins"

# Detect available shell (prefer zsh, fall back to bash)
if command -v zsh >/dev/null 2>&1; then
  DEFAULT_SHELL="zsh"
else
  DEFAULT_SHELL="bash"
fi

# Copy config files, prepend detected shell
{ echo "default_shell \"$DEFAULT_SHELL\""; cat "$REPO_DIR/config.kdl"; } > "$ZELLIJ_CONFIG_DIR/config.kdl"
cp -f "$REPO_DIR/status.sh"                     "$ZELLIJ_CONFIG_DIR/status.sh"
cp -f "$REPO_DIR/configure-icon.sh"             "$ZELLIJ_CONFIG_DIR/configure-icon.sh"
chmod +x "$ZELLIJ_CONFIG_DIR/configure-icon.sh"
cp -f "$REPO_DIR/layouts/default.kdl"            "$ZELLIJ_CONFIG_DIR/layouts/default.kdl"
cp -f "$REPO_DIR/layouts/default.swap.kdl"       "$ZELLIJ_CONFIG_DIR/layouts/default.swap.kdl"
cp -f "$REPO_DIR/themes/catppuccin_mocha.kdl"    "$ZELLIJ_CONFIG_DIR/themes/catppuccin_mocha.kdl"
chmod +x "$ZELLIJ_CONFIG_DIR/status.sh"
echo "    Config files copied"

# Download zjstatus plugin
ZJSTATUS_PATH="$ZELLIJ_CONFIG_DIR/plugins/zjstatus.wasm"
if [[ ! -f "$ZJSTATUS_PATH" ]] || [[ "$FORCE" == "true" ]]; then
  echo "    Downloading zjstatus v${ZJSTATUS_VERSION}..."
  curl -fsSL \
    "https://github.com/dj95/zjstatus/releases/download/v${ZJSTATUS_VERSION}/zjstatus.wasm" \
    -o "$ZJSTATUS_PATH"
  echo "    zjstatus v${ZJSTATUS_VERSION} installed"
else
  echo "    zjstatus already present (use --force to re-download)"
fi

# Pre-grant zjstatus permissions
mkdir -p "$ZELLIJ_CACHE_DIR"
cat > "$ZELLIJ_CACHE_DIR/permissions.kdl" << EOF
"$HOME/.config/zellij/plugins/zjstatus.wasm" {
    ChangeApplicationState
    RunCommands
    ReadApplicationState
}
EOF
echo "    zjstatus permissions configured"

# Set machine icon on first run (random icon + color + auto hostname)
if [[ ! -f "$ZELLIJ_CONFIG_DIR/machine-id.conf" ]]; then
  bash "$ZELLIJ_CONFIG_DIR/configure-icon.sh"
else
  echo "    Machine icon already configured (run ~/.config/zellij/configure-icon.sh --pick to change)"
fi

# Warn about stale sessions if auto-attach is configured
if grep -q 'zellij attach' ~/.bashrc ~/.zshrc 2>/dev/null; then
  SESSION_NAME=$(grep -ohP 'zellij attach \K\S+' ~/.bashrc ~/.zshrc 2>/dev/null | head -1)
  if [[ -n "$SESSION_NAME" ]] && command -v zellij >/dev/null 2>&1; then
    if zellij list-sessions 2>/dev/null | grep -q "$SESSION_NAME"; then
      echo ""
      echo "    NOTE: Existing zellij session '$SESSION_NAME' is still running."
      echo "    Zellij does not reload config for existing sessions."
      echo "    To apply the new config, either:"
      echo "      1. Change the session name in your shell rc (e.g. 'main2' instead of '$SESSION_NAME')"
      echo "      2. Exit all panes in the session (it will be recreated on next login)"
      echo "      3. From inside zellij: Ctrl+o, d (detach), then 'zellij delete-session $SESSION_NAME'"
    fi
  fi
fi

echo "==> Done"
