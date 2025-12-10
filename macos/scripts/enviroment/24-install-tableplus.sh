#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [24] INSTALLING TABLEPLUS =========="
echo "=============================================="

# Check if TablePlus is already installed
TABLEPLUS_INSTALLED=false
if command -v tableplus &> /dev/null; then
    TABLEPLUS_INSTALLED=true
elif [ -d "/Applications/TablePlus.app" ]; then
    TABLEPLUS_INSTALLED=true
fi

if [ "$TABLEPLUS_INSTALLED" = true ]; then
    echo "✓ TablePlus is already installed"
    if [ -d "/Applications/TablePlus.app" ] && command -v defaults &> /dev/null; then
        TABLEPLUS_VERSION=$(defaults read /Applications/TablePlus.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "installed")
        if [ -n "$TABLEPLUS_VERSION" ] && [ "$TABLEPLUS_VERSION" != "installed" ]; then
            echo "  Version: $TABLEPLUS_VERSION"
        fi
    fi
    echo "Skipping installation..."
else
    echo "Installing TablePlus..."

    # Check if Homebrew is available
    if command -v brew &> /dev/null; then
        echo ""
        echo "📥 Installing TablePlus via Homebrew Cask..."

        if brew install --cask tableplus; then
            echo "✓ TablePlus installed successfully via Homebrew"
            INSTALLED=true
        else
            echo "⚠️  Homebrew installation failed, trying direct download..."
            INSTALLED=false
        fi
    else
        INSTALLED=false
    fi

    # Method 2: Direct download if Homebrew failed or not available
    if [ "$INSTALLED" != true ]; then
        echo ""
        echo "📥 Downloading TablePlus directly..."

        # Get latest version from GitHub releases
        LATEST_VERSION=$(curl -s https://api.github.com/repos/TablePlus/TablePlus/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

        if [ -z "$LATEST_VERSION" ]; then
            echo "❌ Failed to get latest TablePlus version"
            echo "   Please install TablePlus manually from: https://tableplus.com/download"
            exit 1
        fi

        echo "  Downloading TablePlus v${LATEST_VERSION}..."

        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        # Download .dmg
        DMG_URL="https://github.com/TablePlus/TablePlus/releases/download/v${LATEST_VERSION}/TablePlus-${LATEST_VERSION}.dmg"
        DMG_FILE="$TEMP_DIR/TablePlus.dmg"

        if curl -sSL "$DMG_URL" -o "$DMG_FILE"; then
            echo "  Mounting and installing..."

            # Mount DMG
            MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse -quiet | tail -1 | awk -F'\t' '{print $3}')

            if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT/TablePlus.app" ]; then
                # Copy to Applications
                sudo cp -R "$MOUNT_POINT/TablePlus.app" /Applications/

                # Unmount
                hdiutil detach "$MOUNT_POINT" -quiet

                echo "✓ TablePlus installed successfully"
                INSTALLED=true
            else
                echo "❌ Failed to mount or find TablePlus.app in DMG"
            fi

            rm -f "$DMG_FILE"
        else
            echo "❌ Failed to download TablePlus"
        fi

        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    fi

    # Final check
    if [ "$INSTALLED" != true ]; then
        echo "❌ Failed to install TablePlus automatically"
        echo ""
        echo "Please install TablePlus manually:"
        echo "  1. Visit: https://tableplus.com/download"
        echo "  2. Download the macOS version"
        echo "  3. Install TablePlus.app to /Applications"
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
echo "🎉 All development tools installation complete!"
