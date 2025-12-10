#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Validate .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found: $ENV_FILE"
    echo ""
    if [ -f "$ENV_EXAMPLE" ]; then
        echo "📝 Please create .env file from template:"
        echo "   cp $ENV_EXAMPLE $ENV_FILE"
        echo "   nano $ENV_FILE"
    else
        echo "📝 Please create .env file:"
        echo "   nano $ENV_FILE"
    fi
    echo ""
    exit 1
fi

# Load .env file
set -a
source "$ENV_FILE"
set +a

echo "=============================================="
echo "===== [22] CONFIGURING GITHUB TOKEN =========="
echo "=============================================="

echo "This script will help you configure the GITHUB_TOKEN"
echo "environment variable needed for private repositories."
echo ""

# Check if token is provided as argument, environment variable, or already configured
if [ -n "$1" ]; then
    GITHUB_TOKEN_INPUT="$1"
    echo "✓ Token provided as argument"
elif [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "skip" ]; then
    # Token was provided at the beginning of installation
    GITHUB_TOKEN_INPUT="$GITHUB_TOKEN"
    echo "✓ Using GitHub token provided at installation start"
else
    # Check if already in .zshrc
    if grep -q "GITHUB_TOKEN" ~/.zshrc 2>/dev/null; then
        echo "⚠️  GITHUB_TOKEN is already configured in ~/.zshrc"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Configuration skipped."
            exit 0
        fi
        # Remove old GITHUB_TOKEN line
        sed -i.bak '/GITHUB_TOKEN/d' ~/.zshrc
    fi
    echo ""
    echo "📝 To get a GitHub token:"
    echo "   1. Go to: https://github.com/settings/tokens"
    echo "   2. Click 'Generate new token' -> 'Generate new token (classic)'"
    echo "   3. Give it a name (e.g., 'Development Token')"
    echo "   4. Select scopes: 'repo' (for private repositories)"
    echo "   5. Click 'Generate token'"
    echo "   6. Copy the token (you won't see it again!)"
    echo ""
    echo "💡 Tip: You can also pass the token as argument:"
    echo "   bash 22-configure-github-token.sh YOUR_TOKEN"
    echo ""
    read -p "Enter your GitHub token (or press Enter to skip): " GITHUB_TOKEN_INPUT
fi

if [ -z "$GITHUB_TOKEN_INPUT" ]; then
    echo "⚠️  Configuration skipped. You can set it manually later:"
    echo "   export GITHUB_TOKEN=your_token_here"
    echo ""
    echo "Or add to ~/.zshrc:"
    echo "   echo 'export GITHUB_TOKEN=your_token_here' >> ~/.zshrc"
    exit 0
fi

# Remove old GITHUB_TOKEN from .zshrc if exists
if grep -q "GITHUB_TOKEN" ~/.zshrc 2>/dev/null; then
    sed -i.bak '/GITHUB_TOKEN/d' ~/.zshrc
fi

# Add to .zshrc
echo "" >> ~/.zshrc
echo "# GitHub Token for private repositories" >> ~/.zshrc
echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN_INPUT\"" >> ~/.zshrc

echo "✓ GITHUB_TOKEN configured in ~/.zshrc"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - The token will be available after restarting the terminal"
echo "   - Or run: source ~/.zshrc"
echo "   - Keep your token secure and don't share it"
echo ""

echo "=============================================="
echo "============== [22] DONE ===================="
echo "=============================================="
echo "🎉 GitHub token configuration complete!"
echo ""
echo "📋 Summary:"
echo "   ✓ GITHUB_TOKEN configured in ~/.zshrc"
echo ""
echo "📝 Next steps:"
echo "   1. Restart your terminal or run: source ~/.zshrc"
echo "   2. Verify: echo \$GITHUB_TOKEN"
echo ""
