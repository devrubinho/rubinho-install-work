#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [02] INSTALLING ZSH ================"
echo "=============================================="

# Load apt helper if available (apt_helper is loaded by 00-install-all.sh)
# But we check here in case script is run standalone
if [ -z "$INSTALL_ALL_RUNNING" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    if [ -f "$PROJECT_ROOT/lib/apt_helper.sh" ]; then
        source "$PROJECT_ROOT/lib/apt_helper.sh"
    fi
fi

# Use safe apt functions if available, otherwise use regular apt
if command -v safe_apt_update &> /dev/null && command -v safe_apt_install &> /dev/null; then
    safe_apt_update
    safe_apt_install zsh curl git
else
    # Fallback if helper not available
    sudo apt update -y
    sudo apt install -y zsh curl git
fi

ZSH_BIN=$(which zsh)

echo "=============================================="
echo "===== [02] SETTING DEFAULT SHELL ============"
echo "=============================================="

if [ "$SHELL" != "$ZSH_BIN" ]; then
  chsh -s "$ZSH_BIN"
  echo "✔ Default shell changed to ZSH"
else
  echo "✔ ZSH is already the default shell"
fi

echo "=============================================="
echo "===== [02] CREATING MINIMAL .zshrc ==========="
echo "=============================================="

cat > ~/.zshrc << 'EOF'
# ==========================================
#  Minimal ZSH bootstrap configuration file
# ==========================================

# Initialize completion system
autoload -Uz compinit
compinit

# Additional helper configurations will be appended below
# --------------------------------------------
EOF

echo "=============================================="
echo "===== [02] MINIMAL CONFIG CREATED ============"
echo "=============================================="
echo "Full ZSH configuration will be added by script 04"

echo "=============================================="
echo "============== [02] DONE ===================="
echo "=============================================="
echo "⚠️  Please close the terminal and open it again."
echo "▶ Next, run: bash 03-install-zinit.sh"
