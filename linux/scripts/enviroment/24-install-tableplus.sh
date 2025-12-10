#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [24] INSTALLING TABLEPLUS =========="
echo "=============================================="

# Check if TablePlus is already installed
TABLEPLUS_INSTALLED=false
if command -v tableplus &> /dev/null; then
    TABLEPLUS_INSTALLED=true
elif [ -f "$HOME/.local/bin/tableplus" ] || [ -f "/usr/bin/tableplus" ] || [ -f "/usr/local/bin/tableplus" ]; then
    TABLEPLUS_INSTALLED=true
elif [ -f "$HOME/Applications/TablePlus.AppImage" ] || [ -f "$HOME/.local/bin/TablePlus-x64.AppImage" ] || [ -f "$HOME/.local/bin/TablePlus-aarch64.AppImage" ]; then
    TABLEPLUS_INSTALLED=true
fi

# Detect architecture for AppImage path
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        APPIMAGE_ARCH="x64"
        APPIMAGE_NAME="TablePlus-x64.AppImage"
        ;;
    aarch64|arm64)
        APPIMAGE_ARCH="aarch64"
        APPIMAGE_NAME="TablePlus-aarch64.AppImage"
        ;;
    *)
        APPIMAGE_NAME=""
        ;;
esac

APPIMAGE_DIR="$HOME/.local/bin"
APPIMAGE_PATH="$APPIMAGE_DIR/$APPIMAGE_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/tableplus.desktop"

if [ "$TABLEPLUS_INSTALLED" = true ]; then
    echo "✓ TablePlus is already installed"
    if command -v tableplus &> /dev/null; then
        TABLEPLUS_VERSION=$(tableplus --version 2>/dev/null || echo "installed")
        if [ -n "$TABLEPLUS_VERSION" ] && [ "$TABLEPLUS_VERSION" != "installed" ]; then
            echo "  Version: $TABLEPLUS_VERSION"
        fi
    fi

    # Check if desktop file exists, if not create it
    if [ ! -f "$DESKTOP_FILE" ] && [ -f "$APPIMAGE_PATH" ]; then
        echo "  Creating desktop entry for application menu..."
        DESKTOP_DIR="$HOME/.local/share/applications"
        mkdir -p "$DESKTOP_DIR"

        cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TablePlus
Comment=Modern database management tool
Exec=$APPIMAGE_PATH
Icon=tableplus
Terminal=false
Categories=Development;Database;
MimeType=application/x-sqlite3;
DESKTOP_EOF

        chmod +x "$DESKTOP_FILE"

        # Try to extract icon
        if [ -f "$APPIMAGE_PATH" ]; then
            ICON_DIR="$HOME/.local/share/icons"
            mkdir -p "$ICON_DIR"
            TEMP_DIR=$(mktemp -d)
            if "$APPIMAGE_PATH" --appimage-extract "*.png" "$TEMP_DIR" 2>/dev/null || \
               "$APPIMAGE_PATH" --appimage-extract "*.svg" "$TEMP_DIR" 2>/dev/null; then
                ICON_FILE=$(find "$TEMP_DIR" -type f \( -name "*.png" -o -name "*.svg" \) | head -1)
                if [ -n "$ICON_FILE" ] && [ -f "$ICON_FILE" ]; then
                    ICON_EXT="${ICON_FILE##*.}"
                    cp "$ICON_FILE" "$ICON_DIR/tableplus.$ICON_EXT" 2>/dev/null && \
                    sed -i "s|Icon=tableplus|Icon=$ICON_DIR/tableplus.$ICON_EXT|" "$DESKTOP_FILE" 2>/dev/null || true
                fi
            fi
            rm -rf "$TEMP_DIR" 2>/dev/null || true
        fi

        # Update desktop database
        if command -v update-desktop-database &> /dev/null; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
            echo "✓ Desktop entry created and database updated"
        else
            echo "✓ Desktop entry created (may need logout/login to appear)"
        fi
    elif [ -f "$DESKTOP_FILE" ]; then
        echo "✓ Desktop entry already exists"
    fi

    echo "Skipping installation..."
else
    echo "Installing TablePlus..."

    INSTALLED=false

    # Detect architecture (if not already detected)
    if [ -z "$ARCH" ]; then
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)
                APPIMAGE_ARCH="x64"
                APPIMAGE_NAME="TablePlus-x64.AppImage"
                ;;
            aarch64|arm64)
                APPIMAGE_ARCH="aarch64"
                APPIMAGE_NAME="TablePlus-aarch64.AppImage"
                ;;
            *)
                echo "❌ Unsupported architecture: $ARCH"
                echo "   TablePlus is only available for x86_64 and aarch64"
                exit 1
                ;;
        esac
    fi

    # Create directory for AppImage if it doesn't exist
    APPIMAGE_DIR="$HOME/.local/bin"
    mkdir -p "$APPIMAGE_DIR"
    APPIMAGE_PATH="$APPIMAGE_DIR/$APPIMAGE_NAME"

    # Method 1: Install via AppImage (simplest method - no sudo needed)
    echo ""
    echo "📥 Installing TablePlus via AppImage (recommended)..."
    echo "  Architecture: $ARCH ($APPIMAGE_ARCH)"

    # Download AppImage
    echo "  Downloading TablePlus AppImage..."
    APPIMAGE_URL="https://tableplus.com/releases/linux/appImage/$APPIMAGE_NAME"

    DOWNLOAD_SUCCESS=false
    if command -v wget &> /dev/null; then
        echo "  Using wget to download..."
        if wget --show-progress -O "$APPIMAGE_PATH" "$APPIMAGE_URL" 2>&1; then
            if [ -f "$APPIMAGE_PATH" ] && [ -s "$APPIMAGE_PATH" ]; then
                DOWNLOAD_SUCCESS=true
                echo "✓ Download completed"
            else
                echo "⚠️  Download completed but file is empty or missing"
            fi
        else
            echo "⚠️  Failed to download AppImage with wget"
        fi
    elif command -v curl &> /dev/null; then
        echo "  Using curl to download..."
        if curl -L --progress-bar -o "$APPIMAGE_PATH" "$APPIMAGE_URL" 2>&1; then
            if [ -f "$APPIMAGE_PATH" ] && [ -s "$APPIMAGE_PATH" ]; then
                DOWNLOAD_SUCCESS=true
                echo "✓ Download completed"
            else
                echo "⚠️  Download completed but file is empty or missing"
            fi
        else
            echo "⚠️  Failed to download AppImage with curl"
        fi
    else
        echo "❌ Neither wget nor curl is available"
    fi

    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        INSTALLED=false
    fi

    if [ -f "$APPIMAGE_PATH" ]; then
        # Make executable
        echo "  Making AppImage executable..."
        chmod +x "$APPIMAGE_PATH"

        # Create symlink for easy access
        if [ ! -f "$APPIMAGE_DIR/tableplus" ]; then
            ln -sf "$APPIMAGE_NAME" "$APPIMAGE_DIR/tableplus"
            echo "✓ Created symlink: $APPIMAGE_DIR/tableplus"
        fi

        # Create desktop file for application menu
        echo "  Creating desktop entry for application menu..."
        DESKTOP_DIR="$HOME/.local/share/applications"
        mkdir -p "$DESKTOP_DIR"
        DESKTOP_FILE="$DESKTOP_DIR/tableplus.desktop"

        cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TablePlus
Comment=Modern database management tool
Exec=$APPIMAGE_PATH
Icon=tableplus
Terminal=false
Categories=Development;Database;
MimeType=application/x-sqlite3;
DESKTOP_EOF

        # Make desktop file executable
        chmod +x "$DESKTOP_FILE"

        # Try to extract icon from AppImage if possible
        if [ -f "$APPIMAGE_PATH" ]; then
            ICON_DIR="$HOME/.local/share/icons"
            mkdir -p "$ICON_DIR"
            # AppImages can be extracted, try to get icon
            TEMP_DIR=$(mktemp -d)
            if "$APPIMAGE_PATH" --appimage-extract "*.png" "$TEMP_DIR" 2>/dev/null || \
               "$APPIMAGE_PATH" --appimage-extract "*.svg" "$TEMP_DIR" 2>/dev/null; then
                ICON_FILE=$(find "$TEMP_DIR" -type f \( -name "*.png" -o -name "*.svg" \) | head -1)
                if [ -n "$ICON_FILE" ] && [ -f "$ICON_FILE" ]; then
                    ICON_EXT="${ICON_FILE##*.}"
                    cp "$ICON_FILE" "$ICON_DIR/tableplus.$ICON_EXT" 2>/dev/null && \
                    sed -i "s|Icon=tableplus|Icon=$ICON_DIR/tableplus.$ICON_EXT|" "$DESKTOP_FILE" 2>/dev/null || true
                fi
            fi
            rm -rf "$TEMP_DIR" 2>/dev/null || true
        fi

        # Make desktop file executable
        chmod +x "$DESKTOP_FILE"

        # Update desktop database (required for menu to show the app)
        if command -v update-desktop-database &> /dev/null; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
            echo "✓ Updated desktop database"
        else
            echo "⚠️  update-desktop-database not found, desktop entry may not appear immediately"
            echo "   Try logging out and back in, or restart your desktop environment"
        fi

        echo "✓ Desktop entry created: $DESKTOP_FILE"
        echo "  The app should appear in your application menu"

        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$APPIMAGE_DIR:"* ]]; then
            echo ""
            echo "💡 To use TablePlus from terminal, add this to your ~/.bashrc or ~/.zshrc:"
            echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo ""
            echo "   Or run: echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
            echo ""
        fi

        echo "✓ TablePlus installed successfully via AppImage"
        echo "  Location: $APPIMAGE_PATH"
        echo "  Desktop entry: $DESKTOP_FILE"
        echo "  Run with: $APPIMAGE_PATH"
        echo "  Or search for 'TablePlus' in your application menu"
        INSTALLED=true
    fi

    # Method 2: Try APT repository if AppImage failed
    if [ "$INSTALLED" = false ] && command -v apt-get &> /dev/null && command -v add-apt-repository &> /dev/null; then
        echo ""
        echo "📥 Trying alternative: Installing TablePlus via APT repository..."

        # Detect Ubuntu version
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            UBUNTU_VERSION=$(echo "$VERSION_ID" | cut -d. -f1,2)
        else
            UBUNTU_VERSION="22"
        fi

        APT_ARCH="amd64"
        if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            APT_ARCH="arm64"
        fi

        # Determine repository URL
        REPO_URL=""
        case "$UBUNTU_VERSION" in
            20.04)
                if [ "$APT_ARCH" = "amd64" ]; then
                    REPO_URL="deb [arch=amd64] https://deb.tableplus.com/debian/20 tableplus main"
                fi
                ;;
            22.04)
                if [ "$APT_ARCH" = "amd64" ]; then
                    REPO_URL="deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"
                else
                    REPO_URL="deb [arch=arm64] https://deb.tableplus.com/debian/22-arm tableplus main"
                fi
                ;;
            24.04)
                if [ "$APT_ARCH" = "amd64" ]; then
                    REPO_URL="deb [arch=amd64] https://deb.tableplus.com/debian/24 tableplus main"
                else
                    REPO_URL="deb [arch=arm64] https://deb.tableplus.com/debian/24-arm tableplus main"
                fi
                ;;
            *)
                if [ "$APT_ARCH" = "amd64" ]; then
                    REPO_URL="deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"
                else
                    REPO_URL="deb [arch=arm64] https://deb.tableplus.com/debian/22-arm tableplus main"
                fi
                ;;
        esac

        if [ -n "$REPO_URL" ] && command -v sudo &> /dev/null; then
            set +e  # Temporarily disable set -e

            # Add GPG key
            echo "  Adding GPG key..."
            if [ "$UBUNTU_VERSION" = "20.04" ]; then
                wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | sudo apt-key add - 2>&1
            else
                wget -qO - https://deb.tableplus.com/apt.tableplus.com.gpg.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/tableplus-archive.gpg > /dev/null 2>&1
            fi

            # Add repository
            echo "  Adding repository..."
            if command -v add-apt-repository &> /dev/null; then
                echo "$REPO_URL" | sudo add-apt-repository -y 2>&1 | grep -q "added\|tableplus" || \
                echo "$REPO_URL" | sudo tee /etc/apt/sources.list.d/tableplus.list > /dev/null 2>&1
            else
                echo "$REPO_URL" | sudo tee /etc/apt/sources.list.d/tableplus.list > /dev/null 2>&1
            fi

            # Update and install
            echo "  Updating package list..."
            if sudo apt-get update -qq 2>&1; then
                echo "  Installing TablePlus..."
                if sudo apt-get install -y tableplus 2>&1; then
                    echo "✓ TablePlus installed successfully via APT"
                    INSTALLED=true
                fi
            fi

            set -e
        fi
    fi

    # Method 3: Try Snap if both failed
    if [ "$INSTALLED" = false ] && command -v snap &> /dev/null; then
        echo ""
        echo "📥 Trying alternative: Installing TablePlus via Snap..."
        if sudo snap install tableplus --classic 2>&1; then
            echo "✓ TablePlus installed successfully via Snap"
            INSTALLED=true
        fi
    fi

    # Final check
    if [ "$INSTALLED" = false ]; then
        echo ""
        echo "❌ Failed to install TablePlus automatically"
        echo ""
        echo "Please install TablePlus manually:"
        echo "  1. Visit: https://tableplus.com/download"
        echo "  2. Download the AppImage for your architecture ($ARCH)"
        echo "  3. Make it executable: chmod +x TablePlus-$APPIMAGE_ARCH.AppImage"
        echo "  4. Run it: ./TablePlus-$APPIMAGE_ARCH.AppImage"
        exit 1
    fi
fi

echo ""
echo "=============================================="
echo "============== [24] DONE ===================="
echo "=============================================="
echo ""
echo "📝 TablePlus is a modern database management tool for:"
echo "   - MySQL, PostgreSQL, SQLite, Redis, and more"
echo ""
if [ -f "$APPIMAGE_PATH" ]; then
    echo "💡 To use TablePlus:"
    echo "   $APPIMAGE_PATH"
    echo ""
    echo "   Or add ~/.local/bin to your PATH and use: tableplus"
fi
echo ""
echo "🎉 All development tools installation complete!"
