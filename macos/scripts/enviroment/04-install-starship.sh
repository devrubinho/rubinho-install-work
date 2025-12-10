#!/usr/bin/env bash

set -e

# Repository configuration
CONFIG_REPO="https://raw.githubusercontent.com/devrubinho/rubinho-install-dev/main"
PLATFORM="macos"

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
echo "========= [04] INSTALLING STARSHIP ==========="
echo "=============================================="

echo "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh

echo "Copying starship.toml..."
mkdir -p ~/.config
TEMP_STARSHIP=$(mktemp)
if download_config "starship.toml" "$TEMP_STARSHIP"; then
  cp "$TEMP_STARSHIP" ~/.config/starship.toml
  rm -f "$TEMP_STARSHIP"
else
  echo "⚠️  Using default Starship configuration"
  rm -f "$TEMP_STARSHIP"
fi

echo "Updating .zshrc with Zinit + Starship + custom config..."
# Download and apply zsh-config from repository
TEMP_ZSH_CONFIG=$(mktemp)
if download_config "zsh-config" "$TEMP_ZSH_CONFIG"; then
  cat "$TEMP_ZSH_CONFIG" > ~/.zshrc
  echo "✓ zsh-config applied successfully"
  rm -f "$TEMP_ZSH_CONFIG"
else
  echo "⚠️  zsh-config not found, using fallback configuration"
  rm -f "$TEMP_ZSH_CONFIG"
  # Fallback if file doesn't exist
  cat >> ~/.zshrc << 'EOF'
# Load Starship prompt
eval "$(starship init zsh)"
EOF
fi

echo "=============================================="
echo "============== [04] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 05-install-node-nvm.sh"
