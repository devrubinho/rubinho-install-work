#!/usr/bin/env bash

# ────────────────────────────────────────────────────────────────
# Module Guard - Prevent Direct Execution
# ────────────────────────────────────────────────────────────────
# This script should only be executed by 00-install-all.sh
if [ -z "$INSTALL_ALL_RUNNING" ]; then
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_SCRIPT="$SCRIPT_DIR/00-install-all.sh"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  This script should not be executed directly"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The script \"$SCRIPT_NAME\" is a module and should only be"
    echo "executed as part of the complete installation process."
    echo ""
    echo "To run the complete installation, use:"
    echo "  bash $INSTALL_SCRIPT"
    echo ""
    echo "Or from the project root:"
    echo "  bash run.sh"
    echo ""
    exit 1
fi


set -e

echo "=============================================="
echo "===== [13] INSTALLING TASK MASTER (MCP) ====="
echo "=============================================="

# ────────────────────────────────
# Check Cursor Installation
# ────────────────────────────────

CURSOR_MCP_DIR="$HOME/.cursor"
MCP_CONFIG_FILE="$CURSOR_MCP_DIR/mcp.json"

if [ ! -d "$CURSOR_MCP_DIR" ]; then
    echo "Creating Cursor MCP directory..."
    mkdir -p "$CURSOR_MCP_DIR"
fi

# ────────────────────────────────
# Install Task Master Automatically
# ────────────────────────────────

echo ""
echo "📦 Installing Task Master MCP Server..."

# Load NVM if available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

# Verify Node.js is available
if ! command -v node &> /dev/null && ! command -v npm &> /dev/null; then
    echo "❌ Node.js/npm not found."
    echo "   Task Master requires Node.js to be installed."
    echo "   Please install Node.js first (script 05-install-node-nvm.sh) and run this script again."
    exit 1
fi

# Check if already installed
if command -v task-master-ai &> /dev/null || npm list -g task-master-ai &> /dev/null 2>&1; then
    echo "✓ Task Master is already installed"
    echo "Skipping installation..."
else
    echo "→ Installing Task Master globally via npm..."
    echo "  This may take 30-60 seconds..."
    if npm install -g task-master-ai; then
        echo "✓ Task Master installed globally"
    else
        echo "❌ Failed to install Task Master"
        exit 1
    fi
fi

# ────────────────────────────────
# Create/Update MCP Configuration
# ────────────────────────────────

echo ""
echo "📝 Configuring MCP settings..."

if [ -f "$MCP_CONFIG_FILE" ]; then
    echo "→ Found existing mcp.json, backing up..."
    cp "$MCP_CONFIG_FILE" "$MCP_CONFIG_FILE.backup"
fi

# ────────────────────────────────
# Create MCP Config
# ────────────────────────────────

# Use jq if available, otherwise use sed/awk
if command -v jq &> /dev/null; then
    # Create JSON with jq
    cat > "$MCP_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "taskmaster-ai": {
      "command": "task-master-ai"
    }
  }
}
EOF
else
    # Fallback: create JSON manually
    cat > "$MCP_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "taskmaster-ai": {
      "command": "task-master-ai"
    }
  }
}
EOF
fi

echo "→ Created/updated mcp.json at: $MCP_CONFIG_FILE"
echo ""

# ────────────────────────────────
# Instructions
# ────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. ⚙️  Enable Task Master in Cursor:"
echo "   - Open Cursor Settings (Ctrl+,)"
echo "   - Go to 'MCP' tab"
echo "   - Enable 'taskmaster-ai' toggle"
echo ""
echo "2. 🚀 Initialize Task Master in your project:"
echo "   - Open Cursor AI chat"
echo "   - Type: 'Inicializar taskmaster-ai no meu projeto'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Documentation: https://docs.task-master.dev/"
echo "🌐 Website: https://www.task-master.dev/"
echo ""

echo "=============================================="
echo "============== [13] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 15-configure-cursor.sh"
