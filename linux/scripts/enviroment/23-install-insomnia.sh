#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [24] INSTALLING INSOMNIA ==========="
echo "=============================================="

# Check if Insomnia is already installed
if command -v insomnia &> /dev/null; then
    echo "✓ Insomnia is already installed"
    echo "Skipping installation..."
else
    echo "Installing Insomnia..."

    # Add Insomnia repository
    echo "Adding Insomnia repository..."

    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /etc/apt/keyrings

    # Add GPG key (modern method)
    echo "Adding GPG key..."
    curl -fsSL https://insomnia.rest/keys/debian-public.key.asc | sudo gpg --dearmor -o /etc/apt/keyrings/insomnia.gpg
    sudo chmod a+r /etc/apt/keyrings/insomnia.gpg

    # Add repository with signed-by
    echo "deb [signed-by=/etc/apt/keyrings/insomnia.gpg] https://dl.bintray.com/getinsomnia/Insomnia /" | sudo tee /etc/apt/sources.list.d/insomnia.list > /dev/null

    # Update package list
    echo "Updating package list..."
    sudo apt-get update -y

    # Install Insomnia
    echo "Installing Insomnia..."
    sudo apt-get install -y insomnia

    # Verify installation
    if command -v insomnia &> /dev/null; then
        echo "✓ Insomnia installed successfully"
    else
        echo "⚠️  Insomnia installed but command not found in PATH"
        echo "   Try restarting your terminal or launching from Applications menu"
    fi
fi

echo "=============================================="
echo "============== [24] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 24-install-tableplus.sh"
