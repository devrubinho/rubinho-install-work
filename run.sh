#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load platform detection library (must be first)
if [ -f "$SCRIPT_DIR/lib/platform.sh" ]; then
    source "$SCRIPT_DIR/lib/platform.sh"
fi

# Load AWS helper library
if [ -f "$SCRIPT_DIR/lib/aws_helper.sh" ]; then
    source "$SCRIPT_DIR/lib/aws_helper.sh"
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 Enterprise Scripts - Interactive Launcher 🚀         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ────────────────────────────────
# Environment Variables Setup
# ────────────────────────────────

setup_environment_variables() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️  Environment Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if .env exists, if not create empty file
    local env_file="$SCRIPT_DIR/.env"
    local env_example="$SCRIPT_DIR/.env.example"

    if [ ! -f "$env_file" ]; then
        echo "📝 Creating new .env file..."
        touch "$env_file"
        echo "✓ Created empty .env file"
        if [ -f "$env_example" ]; then
            echo ""
            echo "💡 Tip: You can use .env.example as a reference:"
            echo "   cat $env_example"
            echo ""
        fi
    fi

    # Show current .env file contents
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Current .env file contents:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ -s "$env_file" ]; then
        # Show contents with line numbers and highlight empty/commented lines
        local line_num=1
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                printf "  %3d: %s\n" "$line_num" "$line"
            elif [[ -z "${line// }" ]]; then
                printf "  %3d: (empty line)\n" "$line_num"
            else
                # Mask sensitive values (tokens, keys, etc)
                local masked_line="$line"
                if [[ "$line" =~ ^[[:space:]]*(GITHUB_TOKEN|AWS_.*_KEY|.*TOKEN|.*SECRET|.*PASSWORD)[[:space:]]*= ]]; then
                    masked_line=$(echo "$line" | sed 's/=.*/=***HIDDEN***/')
                fi
                printf "  %3d: %s\n" "$line_num" "$masked_line"
            fi
            ((line_num++))
        done < "$env_file"
    else
        echo "  (file is empty)"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Ask if user wants to continue with current .env or edit it
    local edited_env=false
    read -p "Is the .env file correct? Continue? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "Opening .env file for editing..."
        echo "  File location: $env_file"
        echo ""

        # Try to use common editors
        if command -v nano &> /dev/null; then
            nano "$env_file"
        elif command -v vim &> /dev/null; then
            vim "$env_file"
        elif command -v vi &> /dev/null; then
            vi "$env_file"
        else
            echo "⚠️  No text editor found (nano, vim, vi)"
            echo "   Please edit the file manually: $env_file"
            echo ""
            read -p "Press Enter after editing the file..."
        fi

        echo ""
        echo "✓ .env file updated"
        echo ""
        edited_env=true
    else
        echo "✓ Continuing with current .env file"
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking required environment variables..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Variables that might be needed for installation
    local required_vars=(
        "GIT_USER_NAME:Your Git user name (for Git commits):true"
        "GIT_USER_EMAIL:Your Git user email (for Git commits):true"
    )


    # Check required variables
    for var_info in "${required_vars[@]}"; do
        IFS=':' read -r var_name prompt_text is_required <<< "$var_info"

        # Check if variable exists in .env
        local value
        if [ -f "$env_file" ]; then
            # Try to read from .env
            while IFS= read -r line || [ -n "$line" ]; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "${line// }" ]] && continue

                # Check if this line matches our variable
                if [[ "$line" =~ ^[[:space:]]*${var_name}[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                    value="${BASH_REMATCH[1]}"
                    # Remove quotes if present
                    value="${value#\"}"
                    value="${value%\"}"
                    value="${value#\'}"
                    value="${value%\'}"
                    # Remove leading/trailing whitespace
                    value="${value#"${value%%[![:space:]]*}"}"
                    value="${value%"${value##*[![:space:]]}"}"
                    break
                fi
            done < "$env_file"
        fi

        # If not found or empty (after removing quotes and spaces), prompt user
        if [ -z "${value// }" ] || [ -z "$value" ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📝 Missing Required Variable: $var_name"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "$prompt_text"
            echo ""

            while true; do
                read -p "Enter value for $var_name: " user_input

                if [ -z "$user_input" ]; then
                    if [ "$is_required" = "true" ]; then
                        echo "❌ Error: $var_name is required and cannot be empty."
                        echo "   Please enter a value."
                        echo ""
                        continue
                    else
                        echo "⚠️  No value provided. Skipping..."
                        echo ""
                        break
                    fi
                else
                    # Save to .env
                    if grep -q "^[[:space:]]*${var_name}[[:space:]]*=" "$env_file" 2>/dev/null; then
                        # Update existing line
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                            sed -i '' "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${user_input}\"|" "$env_file"
                        else
                            sed -i "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${user_input}\"|" "$env_file"
                        fi
                    else
                        # Append new line
                        echo "${var_name}=\"${user_input}\"" >> "$env_file"
                    fi

                    echo "✓ Saved $var_name to .env file"
                    echo ""
                    break
                fi
            done
        else
            echo "✓ Found $var_name in .env file (using existing value)"
        fi
    done


    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Environment configuration complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check for AWS Account variables
    check_aws_account_variables
}

# ────────────────────────────────
# Check AWS Account Variables
# ────────────────────────────────

check_aws_account_variables() {
    local env_file="$SCRIPT_DIR/.env"

    # Check if AWS account variables exist using library function
    if has_aws_account_variables "$env_file"; then
        return 0
    fi

    # If no AWS account variables found, suggest getting them
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "☁️  AWS Account Variables Not Found"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "No AWS account variables (AWS_ACCOUNT_*_ID) found in .env file."
    echo ""

    # Check if AWS config exists
    if [ -f "$HOME/.aws/config" ]; then
        echo "📋 We can extract AWS account information from your AWS configuration."
        echo ""

        read -p "Do you want to see your AWS variables now? [Y/n]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 Your AWS Variables (copy and paste to .env):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""

            # Use library function to get AWS variables
            get_aws_env_variables

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "💡 To add these to your .env file automatically, run:"
            echo "   get_aws_env_variables >> $env_file"
            echo ""

            read -p "Do you want to add these variables to .env now? [y/N]: " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                get_aws_env_variables >> "$env_file"
                echo "✓ AWS variables added to .env file"
            fi

            echo ""
            read -p "Press Enter to continue..."
        fi
    else
        echo "⚠️  AWS configuration file (~/.aws/config) not found."
        echo ""
        echo "To configure AWS SSO, run:"
        echo "   bash $SCRIPT_DIR/linux/scripts/enviroment/18-configure-aws-sso.sh"
        echo ""
        echo "Or for macOS:"
        echo "   bash $SCRIPT_DIR/macos/scripts/enviroment/18-configure-aws-sso.sh"
        echo ""
    fi
    echo ""
}

# Setup environment variables before installation
setup_environment_variables

# ────────────────────────────────
# Platform Detection
# ────────────────────────────────

# Platform is automatically detected by platform.sh
# Verify that detected platform is supported
if [ "$PLATFORM" != "linux" ] && [ "$PLATFORM" != "macos" ]; then
    echo "❌ Error: Unsupported platform detected: $PLATFORM"
    echo "   This script only supports Linux and macOS."
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🖥️  Platform Detected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_platform_info
echo ""

# ────────────────────────────────
# Run Installation Script
# ────────────────────────────────

INSTALL_SCRIPT="$SCRIPT_DIR/$PLATFORM/scripts/enviroment/00-install-all.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "❌ Error: Installation script not found at $INSTALL_SCRIPT"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Installation for $PLATFORM_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the installation script
cd "$(dirname "$INSTALL_SCRIPT")"
bash "$INSTALL_SCRIPT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
