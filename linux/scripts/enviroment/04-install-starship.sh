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
echo "========= [04] INSTALLING STARSHIP ==========="
echo "=============================================="

# Check if Starship is already installed
if command -v starship &> /dev/null; then
    echo "✓ Starship is already installed: $(starship --version)"
    echo "Skipping installation..."
else
    echo "Installing Starship prompt..."

    # Detect architecture
    ARCH=$(uname -m)
    INSTALLED=false

    # Try official install script first
    INSTALL_OUTPUT=$(curl -sS https://starship.rs/install.sh | sh -s -- --yes 2>&1)

    if echo "$INSTALL_OUTPUT" | grep -qi "x86_64 builds.*not yet available\|not yet available.*x86_64"; then
        echo "⚠️  Official installer reported architecture issue, trying alternative methods..."
        INSTALLED=false
    elif command -v starship &> /dev/null; then
        echo "✓ Starship installed successfully via official script"
        INSTALLED=true
    elif echo "$INSTALL_OUTPUT" | grep -qi "installed\|success"; then
        # Check again after a moment
        sleep 1
        if command -v starship &> /dev/null; then
            echo "✓ Starship installed successfully via official script"
            INSTALLED=true
        else
            INSTALLED=false
        fi
    else
        INSTALLED=false
    fi

    # If official script failed, try alternative methods
    if [ "$INSTALLED" = false ]; then
        echo "Trying alternative installation method..."

        # Method 1: Try installing via cargo (if Rust is installed)
        if command -v cargo &> /dev/null; then
            echo "Installing via Cargo..."
            if cargo install starship --locked 2>&1; then
                echo "✓ Starship installed successfully via Cargo"
                INSTALLED=true
            fi
        fi

        # Method 2: Download binary directly from GitHub releases
        if [ "$INSTALLED" = false ]; then
            echo "Downloading binary from GitHub releases..."
            STARSHIP_BIN="$HOME/.local/bin/starship"
            mkdir -p "$HOME/.local/bin"

            # Detect correct architecture for GitHub release
            case "$ARCH" in
                x86_64)
                    RELEASE_ARCH="x86_64-unknown-linux-gnu"
                    ;;
                aarch64|arm64)
                    RELEASE_ARCH="aarch64-unknown-linux-gnu"
                    ;;
                *)
                    RELEASE_ARCH="x86_64-unknown-linux-gnu"
                    echo "⚠️  Unknown architecture $ARCH, defaulting to x86_64"
                    ;;
            esac

            # Get latest version
            LATEST_VERSION=$(curl -s https://api.github.com/repos/starship/starship/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

            if [ -n "$LATEST_VERSION" ]; then
                DOWNLOAD_URL="https://github.com/starship/starship/releases/download/v${LATEST_VERSION}/starship-${RELEASE_ARCH}.tar.gz"
                echo "Downloading from: $DOWNLOAD_URL"

                TEMP_DIR=$(mktemp -d)
                if curl -sSL "$DOWNLOAD_URL" -o "$TEMP_DIR/starship.tar.gz"; then
                    cd "$TEMP_DIR"
                    tar -xzf starship.tar.gz
                    if [ -f "starship" ]; then
                        chmod +x starship
                        mv starship "$STARSHIP_BIN"
                        echo "✓ Starship installed successfully from GitHub release"
                        INSTALLED=true
                    fi
                    cd - > /dev/null
                    rm -rf "$TEMP_DIR"
                fi
            fi
        fi

        # Add to PATH if installed
        if [ "$INSTALLED" = true ] && [ -f "$STARSHIP_BIN" ]; then
            # Add to PATH in .zshrc if not already there
            if ! grep -q "$HOME/.local/bin" ~/.zshrc 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
            fi
            export PATH="$HOME/.local/bin:$PATH"
        fi

        # Final check
        if [ "$INSTALLED" = false ]; then
            echo "⚠️  Automatic installation failed."
            echo ""
            echo "Please install Starship manually:"
            echo "  1. Visit: https://starship.rs/guide/#%F0%9F%9A%80-installation"
            echo "  2. Follow the installation instructions for your system"
            echo ""
            echo "Or install via package manager:"
            echo "  - Ubuntu/Debian: sudo snap install starship"
            echo "  - Or build from source: cargo install starship"
            exit 1
        fi
    fi
fi

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
