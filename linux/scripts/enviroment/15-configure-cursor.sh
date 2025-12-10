#!/usr/bin/env bash

set -e

# Repository configuration
CONFIG_REPO="https://raw.githubusercontent.com/devrubinho/rubinho-install-dev/main"
PLATFORM="linux"

# Function to download config file from repository
download_config() {
  local config_file="$1"
  local output_path="$2"
  local url="${CONFIG_REPO}/${PLATFORM}/config/${config_file}"

  echo "Downloading ${config_file} from repository..."
  if curl -sSf "$url" -o "$output_path"; then
    echo "✓ ${config_file} downloaded successfully"
    return 0
  else
    echo "⚠️  Failed to download ${config_file} from repository"
    return 1
  fi
}

echo "=============================================="
echo "========= [15] CONFIGURING CURSOR ============"
echo "=============================================="

# Determine Cursor user directory based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  CURSOR_USER_DIR="$HOME/.config/Cursor/User"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
else
  echo "❌ Operating system not automatically supported."
  exit 1
fi

mkdir -p "$CURSOR_USER_DIR"

SETTINGS_PATH="$CURSOR_USER_DIR/settings.json"
KEYBINDINGS_PATH="$CURSOR_USER_DIR/keybindings.json"

echo "Detected Cursor directory: $CURSOR_USER_DIR"
echo ""

echo "Downloading settings.json..."
TEMP_SETTINGS=$(mktemp)
if download_config "user-settings.json" "$TEMP_SETTINGS"; then
  cp "$TEMP_SETTINGS" "$SETTINGS_PATH"
  echo "→ settings.json updated successfully!"
  rm -f "$TEMP_SETTINGS"
else
  echo "⚠️  Failed to download settings.json"
  rm -f "$TEMP_SETTINGS"
fi

echo "Downloading keybindings.json..."
TEMP_KEYBINDINGS=$(mktemp)
if download_config "cursor-keyboard.json" "$TEMP_KEYBINDINGS"; then
  cp "$TEMP_KEYBINDINGS" "$KEYBINDINGS_PATH"
  echo "→ keybindings.json updated successfully!"
  rm -f "$TEMP_KEYBINDINGS"
else
  echo "⚠️  Failed to download keybindings.json"
  rm -f "$TEMP_KEYBINDINGS"
fi

echo "=============================================="
echo "============== [15] DONE ===================="
echo "=============================================="
echo "🎉 Cursor configured successfully!"
echo "   Open Cursor again to apply everything."
echo ""
echo "▶ Next, run: bash 16-install-docker.sh (final step)"
