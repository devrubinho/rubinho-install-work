#!/usr/bin/env bash

set -e

# Check if running as root/sudo
if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
    echo "=============================================="
    echo "⚠️  WARNING: Running as root/sudo"
    echo "=============================================="
    echo ""
    echo "This script should NOT be run with sudo!"
    echo ""
    echo "Problems with running as root:"
    echo "  ❌ Configurations will be installed for root, not your user"
    echo "  ❌ Home directory will be /root instead of ~"
    echo "  ❌ Environment variables won't be preserved"
    echo "  ❌ .env file will be read as root"
    echo ""
    echo "The script will use sudo automatically when needed"
    echo "for specific operations (like installing system packages)."
    echo ""
    read -p "Do you want to continue anyway? (NOT RECOMMENDED) (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Please run without sudo:"
        echo "  bash linux/scripts/enviroment/00-install-all.sh"
        exit 1
    fi
    echo ""
    echo "⚠️  Continuing as root (NOT RECOMMENDED)..."
    echo ""
fi

echo "=============================================="
echo "========= COMPLETE INSTALLATION =============="
echo "=============================================="
echo ""
echo "This script will install and configure your development environment."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Load check_installed functions
if [ -f "$PROJECT_ROOT/lib/check_installed.sh" ]; then
    source "$PROJECT_ROOT/lib/check_installed.sh"
fi

# Load apt helper functions
if [ -f "$PROJECT_ROOT/lib/apt_helper.sh" ]; then
    source "$PROJECT_ROOT/lib/apt_helper.sh"
fi

# Load environment variables from .env file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "📝 Loading configuration from .env file..."
    # Source the .env file, ignoring comments and empty lines
    set -a
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Export the variable
        eval "export $line" 2>/dev/null || true
    done < "$ENV_FILE"
    set +a
    echo "✓ Configuration loaded from .env"
elif [ -f "$ENV_EXAMPLE" ]; then
    echo "📝 .env file not found. Creating from .env.example..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "✓ Created .env file from template"
    echo ""
    echo "⚠️  Please edit .env file with your information:"
    echo "   $ENV_FILE"
    echo ""
    echo "   Or run: bash setup-env.sh"
    echo ""
    read -p "Press Enter after editing .env file to continue, or Ctrl+C to cancel..."
    # Reload after user edits
    set -a
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Export the variable
        eval "export $line" 2>/dev/null || true
    done < "$ENV_FILE"
    set +a
fi

# Validate required configuration from .env
echo "📝 Validating configuration from .env file..."
echo ""

# Check Git user name
if [ -z "$GIT_USER_NAME" ] || [ "$GIT_USER_NAME" = "Your Name" ]; then
    echo "❌ GIT_USER_NAME is required in .env file"
    echo "   Please set GIT_USER_NAME in: $ENV_FILE"
    exit 1
fi

# Check Git email
if [ -z "$GIT_USER_EMAIL" ] || [ "$GIT_USER_EMAIL" = "your.email@example.com" ]; then
    echo "❌ GIT_USER_EMAIL is required in .env file"
    echo "   Please set GIT_USER_EMAIL in: $ENV_FILE"
    exit 1
fi

# GitHub token is optional, no validation needed

# Export variables for child scripts
export GIT_USER_NAME
export GIT_USER_EMAIL
export GITHUB_TOKEN
export INSTALL_ALL_RUNNING=1

echo ""
echo "=============================================="
echo "Configuration summary:"
echo "  Git Name: $GIT_USER_NAME"
echo "  Git Email: $GIT_USER_EMAIL"
if [ -n "$GITHUB_TOKEN" ]; then
    echo "  GitHub Token: ${GITHUB_TOKEN:0:10}... (configured)"
else
    echo "  GitHub Token: (not configured)"
fi
echo "=============================================="
echo ""
echo "⚠️  ATTENTION:"
echo "   - After Docker installation (final step), you may need to"
echo "     logout/login to use Docker without sudo (Linux only)."
echo ""

# Part 1: Initial setup (01-02)
echo ""
echo "=============================================="
echo "PHASE 1: Initial Setup"
echo "=============================================="

scripts_phase1=(
  "01-configure-git.sh"
  "02-install-zsh.sh"
)

for script in "${scripts_phase1[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Always ask user if they want to run/install
  if [ -t 0 ]; then  # Check if running interactively
    read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Skipping $script"
      continue
    else
      echo "Installing/running $script..."
    fi
  else
    # Non-interactive mode - run automatically
    echo "Installing/running $script (non-interactive mode)..."
  fi

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

echo ""
echo "=============================================="
echo "PHASE 2: Environment Configuration"
echo "=============================================="

# Part 2: Environment setup (03-04)
scripts_phase2=(
  "03-install-zinit.sh"
  "04-install-starship.sh"
)

for script in "${scripts_phase2[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Always ask user if they want to run/install
  if [ -t 0 ]; then  # Check if running interactively
    read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Skipping $script"
      continue
    else
      echo "Installing/running $script..."
    fi
  else
    # Non-interactive mode - run automatically
    echo "Installing/running $script (non-interactive mode)..."
  fi

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

echo ""
echo "=============================================="
echo "PHASE 3: Development Tools"
echo "=============================================="

# Part 3: Development tools (05-08)
scripts=(
  "05-install-node-nvm.sh"
  "06-install-yarn.sh"
  "07-install-tools.sh"
  "08-install-font-jetbrains.sh"
)

for script in "${scripts[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Always ask user if they want to run/install
  if [ -t 0 ]; then  # Check if running interactively
    read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Skipping $script"
      continue
    else
      echo "Installing/running $script..."
    fi
  else
    # Non-interactive mode - run automatically
    echo "Installing/running $script (non-interactive mode)..."
  fi

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

echo ""
echo "=============================================="
echo "PHASE 4: Application Setup"
echo "=============================================="

# Part 4: Applications and configuration
scripts=(
  "09-install-cursor.sh"
  "10-install-claude.sh"
  "11-configure-terminal.sh"
  "12-configure-ssh.sh"
  "13-configure-inotify.sh"
  "14-install-task-master.sh"
  "15-configure-cursor.sh"
  "16-install-docker.sh"
  "17-install-aws-vpn-client.sh"
  "18-install-aws-cli.sh"
  "19-configure-aws-sso.sh"
  "20-install-dotnet.sh"
  "21-install-java.sh"
  "22-configure-github-token.sh"
  "23-install-insomnia.sh"
  "24-install-tableplus.sh"
)

for script in "${scripts[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Always ask user if they want to run/install
  if [ -t 0 ]; then  # Check if running interactively
    read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Skipping $script"
      continue
    else
      echo "Installing/running $script..."
    fi
  else
    # Non-interactive mode - run automatically
    echo "Installing/running $script (non-interactive mode)..."
  fi

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

echo ""
echo "=============================================="
echo "🎉 INSTALLATION COMPLETE!"
echo "=============================================="
echo "All scripts have been executed successfully!"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Close and reopen your terminal to ensure"
echo "     all configurations are loaded."
echo "   - On Linux: You may need to logout/login to"
echo "     use Docker without sudo."
echo ""
echo "After restarting, verify installations:"
echo "  node -v"
echo "  yarn -v"
echo "  docker --version"
echo ""
