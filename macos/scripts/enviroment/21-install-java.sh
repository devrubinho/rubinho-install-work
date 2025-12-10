#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [22] INSTALLING JAVA 11 ============"
echo "=============================================="

# Check if Java is already installed
if command -v java &> /dev/null; then
    CURRENT_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)

    if [ "$MAJOR_VERSION" = "11" ]; then
        echo "✓ Java 11 is already installed (version: $CURRENT_VERSION)"
        echo "Skipping installation..."

        # Verify JAVA_HOME is set
        if [ -z "$JAVA_HOME" ]; then
            echo "⚠️  JAVA_HOME is not set. Setting it up..."
            JAVA_HOME_PATH=$(readlink -f $(which java) | sed "s:bin/java::")
            echo "export JAVA_HOME=$JAVA_HOME_PATH" >> ~/.zshrc
            echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
            echo "✓ JAVA_HOME configured (will be available after restart)"
        fi
    else
        echo "⚠️  Java $MAJOR_VERSION is installed, but Java 11 is required"
        echo "Installing Java 11..."
    fi
else
    echo "Installing OpenJDK 11..."
fi

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install OpenJDK 11
echo "Installing OpenJDK 11..."
sudo apt-get install -y openjdk-11-jdk

# Set JAVA_HOME
JAVA_HOME_PATH=$(readlink -f $(which java) | sed "s:bin/java::")
if ! grep -q "JAVA_HOME" ~/.zshrc 2>/dev/null; then
    echo "Configuring JAVA_HOME..."
    echo "" >> ~/.zshrc
    echo "# Java 11 Configuration" >> ~/.zshrc
    echo "export JAVA_HOME=$JAVA_HOME_PATH" >> ~/.zshrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
    echo "✓ JAVA_HOME configured (will be available after restart)"
fi

# Verify installation
if command -v java &> /dev/null; then
    INSTALLED_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✓ Java installed successfully"
    echo "  $INSTALLED_VERSION"

    # Show Java version details
    echo ""
    echo "Java details:"
    java -version
else
    echo "❌ Java installation failed"
    exit 1
fi

echo "=============================================="
echo "============== [22] DONE ===================="
echo "=============================================="
echo "⚠️  Restart terminal or run: source ~/.zshrc"
echo "▶ Next, run: bash 22-configure-github-token.sh"
