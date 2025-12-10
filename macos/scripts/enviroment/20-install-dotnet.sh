#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [21] INSTALLING DOTNET 8 ==========="
echo "=============================================="

# Check if .NET is already installed
if command -v dotnet &> /dev/null; then
    CURRENT_VERSION=$(dotnet --version 2>/dev/null | head -n 1)
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)

    if [ "$MAJOR_VERSION" = "8" ]; then
        echo "✓ .NET 8 is already installed (version: $CURRENT_VERSION)"
        echo "Skipping installation..."
    else
        echo "⚠️  .NET $MAJOR_VERSION is installed, but .NET 8 is required"
        echo "Installing .NET 8..."
    fi
else
    echo "Installing .NET SDK 8..."
fi

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "0")
else
    echo "⚠️  Cannot detect Ubuntu version"
    exit 1
fi

echo "Detected Ubuntu version: $UBUNTU_VERSION"
echo ""

# Add Microsoft repository
echo "Adding Microsoft repository..."
wget https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install .NET SDK 8
echo "Installing .NET SDK 8.0..."
sudo apt-get install -y dotnet-sdk-8.0

# Verify installation
if command -v dotnet &> /dev/null; then
    INSTALLED_VERSION=$(dotnet --version)
    echo "✓ .NET SDK installed successfully (version: $INSTALLED_VERSION)"

    # Show installed SDKs
    echo ""
    echo "Installed SDKs:"
    dotnet --list-sdks
else
    echo "❌ .NET SDK installation failed"
    exit 1
fi

echo "=============================================="
echo "============== [21] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 21-install-java.sh"
