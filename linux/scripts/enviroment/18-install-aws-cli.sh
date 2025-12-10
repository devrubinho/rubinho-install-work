#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [19] INSTALLING AWS CLI ============"
echo "=============================================="

# Check if AWS CLI is already installed
if command -v aws &> /dev/null; then
    CURRENT_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
    echo "AWS CLI is already installed (version: $CURRENT_VERSION)"
    echo "Skipping installation..."
else
    echo "Installing AWS CLI v2..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH_TYPE="x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH_TYPE="aarch64"
    else
        echo "⚠️  Unsupported architecture: $ARCH"
        cd -
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo "Detected architecture: $ARCH_TYPE"
    echo "Downloading AWS CLI v2..."
    
    # Download AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH_TYPE}.zip" -o "awscliv2.zip"
    
    # Install unzip if not present
    if ! command -v unzip &> /dev/null; then
        echo "Installing unzip..."
        sudo apt-get update -y
        sudo apt-get install -y unzip
    fi
    
    echo "Extracting AWS CLI..."
    unzip -q awscliv2.zip
    
    echo "Installing AWS CLI..."
    sudo ./aws/install
    
    # Verify installation
    if command -v aws &> /dev/null; then
        INSTALLED_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
        echo "✓ AWS CLI installed successfully (version: $INSTALLED_VERSION)"
    else
        echo "❌ AWS CLI installation failed"
        cd -
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    cd -
    rm -rf "$TEMP_DIR"
fi

echo "=============================================="
echo "============== [19] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 18-configure-aws-sso.sh"

