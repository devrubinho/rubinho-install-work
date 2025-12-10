#!/usr/bin/env bash

set -e

echo "=============================================="
echo "===== [18] INSTALLING AWS VPN CLIENT ========="
echo "=============================================="

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    echo "⚠️  Cannot detect Linux distribution"
    exit 1
fi

echo "Detected distribution: $DISTRO $VERSION"
echo ""

# Function to install for Ubuntu/Debian
install_ubuntu() {
    echo "Installing AWS VPN Client for Ubuntu/Debian..."
    
    # Check Ubuntu version
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "0")
    MAJOR_VERSION=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
    
    # Try modern installation method for Ubuntu 22.04+
    if [ "$MAJOR_VERSION" -ge 22 ]; then
        echo "Detected Ubuntu 22.04+, using modern installation method..."
        
        echo "Adding AWS VPN Client repository..."
        wget -qO- https://d20adtppz83p9s.cloudfront.net/GTK/latest/debian-repo/awsvpnclient_public_key.asc | \
            sudo tee /etc/apt/trusted.gpg.d/awsvpnclient_public_key.asc > /dev/null
        
        echo "deb [arch=amd64] https://d20adtppz83p9s.cloudfront.net/GTK/latest/debian-repo ubuntu main" | \
            sudo tee /etc/apt/sources.list.d/aws-vpn-client.list > /dev/null
        
        echo "Updating package list..."
        sudo apt-get update -y
        
        echo "Installing AWS VPN Client..."
        sudo apt-get install -y awsvpnclient
        
        echo "✓ AWS VPN Client installed via repository"
    else
        # Fallback to manual .deb installation for Ubuntu 20.04 or older
        echo "Using manual .deb installation method (Ubuntu 20.04 or older)..."
        
        # Create temporary directory
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        echo ""
        echo "Downloading AWS VPN Client..."
        echo "⚠️  Please download awsvpnclient_amd64.deb from AWS website"
        echo "    URL: https://aws.amazon.com/vpn/client-vpn-download/"
        echo ""
        read -p "Press Enter after you have downloaded the file to $TEMP_DIR/awsvpnclient_amd64.deb, or type 'skip' to continue with libssl installation: " response
        
        if [ "$response" != "skip" ] && [ -f "$TEMP_DIR/awsvpnclient_amd64.deb" ]; then
            echo "Installing AWS VPN Client package..."
            sudo dpkg -i "$TEMP_DIR/awsvpnclient_amd64.deb" || {
                echo "Fixing dependencies..."
                sudo apt-get install -f -y
            }
            echo "✓ AWS VPN Client installed"
            
            echo ""
            echo "Installing libssl1.1 (required for AWS VPN Client on older Ubuntu versions)..."
            
            # Try to download libssl1.1 - try latest version first
            LIBSSL_VERSIONS=(
                "1.1.1f-1ubuntu2.23"
                "1.1.1f-1ubuntu2.22"
                "1.1.1f-1ubuntu2.21"
            )
            
            LIBSSL_INSTALLED=false
            for version in "${LIBSSL_VERSIONS[@]}"; do
                echo "Trying libssl1.1 version: $version"
                if wget -q "http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_${version}_amd64.deb" -O "libssl1.1_${version}_amd64.deb"; then
                    echo "Downloaded libssl1.1_${version}_amd64.deb"
                    sudo dpkg -i "libssl1.1_${version}_amd64.deb" || {
                        echo "Fixing dependencies..."
                        sudo apt-get install -f -y
                    }
                    LIBSSL_INSTALLED=true
                    echo "✓ libssl1.1 installed successfully"
                    break
                else
                    echo "Version $version not available, trying next..."
                fi
            done
            
            if [ "$LIBSSL_INSTALLED" = false ]; then
                echo "⚠️  Could not download libssl1.1 automatically"
                echo "    Please download manually from:"
                echo "    http://security.ubuntu.com/ubuntu/pool/main/o/openssl/"
                echo "    And install with: sudo dpkg -i libssl1.1_*.deb"
            fi
        else
            echo "⚠️  Skipping AWS VPN Client installation (file not found)"
        fi
        
        # Cleanup
        cd -
        rm -rf "$TEMP_DIR"
    fi
}

# Function to install for Fedora
install_fedora() {
    echo "Installing AWS VPN Client for Fedora..."
    
    echo "Enabling AWS RPM packages repository..."
    sudo dnf copr enable vorona/aws-rpm-packages -y
    
    echo "Installing AWS VPN Client..."
    sudo dnf install -y awsvpnclient
    
    echo "Starting AWS VPN Client service..."
    sudo systemctl start awsvpnclient
    sudo systemctl enable awsvpnclient
    
    echo "✓ AWS VPN Client installed and started"
}

# Install based on distribution
case $DISTRO in
    ubuntu|debian)
        install_ubuntu
        ;;
    fedora)
        install_fedora
        ;;
    *)
        echo "⚠️  Unsupported distribution: $DISTRO"
        echo "    Please install AWS VPN Client manually"
        exit 1
        ;;
esac

echo ""
echo "=============================================="
echo "============== [18] DONE ===================="
echo "=============================================="
echo ""
echo "📝 IMPORTANT NOTES:"
echo ""
echo "1. Configuration:"
echo "   - You need to import a configuration file when"
echo "     running the client for the first time"
echo "   - Access the configuration file from the"
echo "     Access Portal (second option)"
echo ""
echo "2. Docker compatibility:"
echo "   - If Docker is running when you start the VPN,"
echo "   - Docker services may stop working"
echo "   - To fix, run: sudo systemctl restart docker"
echo ""
echo "3. First run:"
echo "   - Open AWS VPN Client from applications menu"
echo "   - Import your configuration file"
echo "   - Connect to your VPN"
echo ""
echo "🎉 AWS VPN Client installation complete!"

