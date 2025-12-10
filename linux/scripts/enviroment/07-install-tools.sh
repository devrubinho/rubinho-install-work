#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [07] INSTALLING TOOLS ============"
echo "=============================================="

echo "Installing productivity tools..."

# Check which tools are already installed
TOOLS_TO_INSTALL=()
TOOLS_ALREADY_INSTALLED=()

check_tool() {
    local tool="$1"
    if command -v "$tool" &> /dev/null; then
        TOOLS_ALREADY_INSTALLED+=("$tool")
        return 0
    else
        TOOLS_TO_INSTALL+=("$tool")
        return 0  # Return 0 to not trigger set -e
    fi
}

# Check tools (fd is installed as fdfind in apt)
# Temporarily disable set -e for checks
set +e
check_tool zoxide
check_tool fzf
if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
    TOOLS_ALREADY_INSTALLED+=("fd")
else
    TOOLS_TO_INSTALL+=("fd-find")
fi
check_tool bat
check_tool lsd
set -e  # Re-enable set -e

# Show already installed tools
if [ ${#TOOLS_ALREADY_INSTALLED[@]} -gt 0 ]; then
    echo "Tools already installed:"
    for tool in "${TOOLS_ALREADY_INSTALLED[@]}"; do
        echo "  ✓ $tool"
    done
    echo ""

    if [ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]; then
        echo "All tools are already installed."
        if [ -t 0 ]; then  # Check if running interactively
            read -p "Do you want to reinstall all tools? [y/N]: " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipping tool installation (all already installed)"
                TOOLS_TO_INSTALL=()
            else
                # Add all tools back for reinstall
                TOOLS_TO_INSTALL=("zoxide" "fzf" "fd-find" "bat" "lsd")
                TOOLS_ALREADY_INSTALLED=()
            fi
        else
            echo "Skipping tool installation (all already installed, non-interactive mode)"
            TOOLS_TO_INSTALL=()
        fi
    fi
fi

# Update package list if we need to install anything
if [ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]; then
    echo "Tools to install: ${TOOLS_TO_INSTALL[*]}"

    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        echo "❌ sudo is not available"
        echo "   Please install sudo or run as root"
        exit 1
    fi

    # Check if we can use sudo without password (for non-interactive mode)
    if [ ! -t 0 ]; then
        # Non-interactive mode - check if passwordless sudo works
        if ! sudo -n true 2>/dev/null; then
            echo "❌ Cannot install tools: sudo requires password but no terminal available"
            echo ""
            echo "Solutions:"
            echo "  1. Run the installation script interactively:"
            echo "     bash linux/scripts/enviroment/00-install-all.sh"
            echo ""
            echo "  2. Configure passwordless sudo for apt commands:"
            echo "     echo '$USER ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get' | sudo tee /etc/sudoers.d/$USER-apt"
            echo ""
            echo "Tools that need installation: ${TOOLS_TO_INSTALL[*]}"
            exit 1
        fi
    fi

    echo "Updating package list..."
    if ! sudo apt update -y; then
        echo "❌ Failed to update package list"
        exit 1
    fi

    # Install tools available in repositories
    echo "Installing tools from repositories..."
    if sudo apt install -y "${TOOLS_TO_INSTALL[@]}"; then
        echo "✓ Successfully installed: ${TOOLS_TO_INSTALL[*]}"
    else
        echo "❌ Failed to install tools: ${TOOLS_TO_INSTALL[*]}"
        exit 1
    fi
fi

# Check if lazygit is already installed
LAZYGIT_INSTALLED=false
if command -v lazygit &> /dev/null; then
    LAZYGIT_INSTALLED=true
    LAZYGIT_VERSION=$(lazygit --version 2>/dev/null | head -1 || echo "installed")
    echo "✓ lazygit is already installed"
    if [ -n "$LAZYGIT_VERSION" ] && [ "$LAZYGIT_VERSION" != "installed" ]; then
        echo "  Version: $LAZYGIT_VERSION"
    fi
    if [ -t 0 ]; then  # Check if running interactively
        read -p "Do you want to reinstall lazygit? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping lazygit installation (already installed)"
            LAZYGIT_INSTALLED=true
        else
            LAZYGIT_INSTALLED=false
        fi
    else
        echo "Skipping lazygit installation (already installed, non-interactive mode)"
        LAZYGIT_INSTALLED=true
    fi
fi

# Install lazygit from GitHub releases if not installed or user wants to reinstall
if [ "$LAZYGIT_INSTALLED" = false ]; then
    echo ""
    echo "Installing lazygit from GitHub releases..."

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            LAZYGIT_ARCH="x86_64"
            ;;
        aarch64|arm64)
            LAZYGIT_ARCH="arm64"
            ;;
        armv7l)
            LAZYGIT_ARCH="armv6"
            ;;
        *)
            echo "⚠️  Unknown architecture $ARCH, trying x86_64"
            LAZYGIT_ARCH="x86_64"
            ;;
    esac

    # Get latest version
    LATEST_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

    if [ -z "$LATEST_VERSION" ]; then
        echo "❌ Failed to get latest lazygit version"
        echo "   Please install lazygit manually from: https://github.com/jesseduffield/lazygit/releases"
        exit 1
    fi

    echo "  Downloading lazygit v${LATEST_VERSION} for ${LAZYGIT_ARCH}..."

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Download lazygit
    DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LATEST_VERSION}/lazygit_${LATEST_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"

    if curl -sSL "$DOWNLOAD_URL" -o lazygit.tar.gz; then
        # Extract
        tar -xzf lazygit.tar.gz

        # Install
        if [ -f "lazygit" ]; then
            chmod +x lazygit
            sudo mv lazygit /usr/local/bin/lazygit
            echo "✓ lazygit installed successfully"
        else
            echo "❌ lazygit binary not found in archive"
            cd - > /dev/null
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    else
        echo "❌ Failed to download lazygit"
        echo "   Download URL: $DOWNLOAD_URL"
        echo "   Please install manually from: https://github.com/jesseduffield/lazygit/releases"
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Create symlinks for fd (apt installs as fdfind)
if [ ! -L /usr/local/bin/fd ] && [ -f /usr/bin/fdfind ]; then
  sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
fi

# Install FZF keybindings
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
  echo "✓ FZF keybindings available"
else
  echo "⚠️  FZF keybindings not found, they may be in a different location"
fi

echo ""
echo "Installed tools:"
echo "  ✓ zoxide - smart cd"
echo "  ✓ fzf - fuzzy finder"
echo "  ✓ fd - fast find"
echo "  ✓ bat - better cat"
echo "  ✓ lsd - better ls"
echo "  ✓ lazygit - git TUI"

echo "=============================================="
echo "============== [07] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 08-install-font-jetbrains.sh"
