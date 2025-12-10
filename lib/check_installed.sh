#!/usr/bin/env bash

# Function to check if a tool/application is installed
# Usage: check_installed "tool_name" [additional_check_command]
check_installed() {
    local tool="$1"
    local additional_check="${2:-}"

    # Check if command exists
    if command -v "$tool" &> /dev/null; then
        return 0
    fi

    # Check common installation paths (Linux)
    if [ -f "/usr/bin/$tool" ] || [ -f "/usr/local/bin/$tool" ] || [ -f "$HOME/.local/bin/$tool" ]; then
        return 0
    fi

    # Check macOS Applications directory
    if [ -d "/Applications/${tool}.app" ] || [ -d "/Applications/${tool^}.app" ]; then
        return 0
    fi

    # Check Homebrew installations (macOS)
    if command -v brew &> /dev/null; then
        if brew list "$tool" &> /dev/null 2>&1 || brew list --cask "$tool" &> /dev/null 2>&1; then
            return 0
        fi
    fi

    # Run additional check if provided
    if [ -n "$additional_check" ]; then
        if eval "$additional_check" &> /dev/null; then
            return 0
        fi
    fi

    return 1
}

# Function to check if a specific script's tool is installed
# Maps script names to their tool checks
check_script_installed() {
    local script_name="$1"

    case "$script_name" in
        "01-configure-git.sh")
            # Git config is always checked, skip this
            return 1
            ;;
        "02-install-zsh.sh")
            check_installed "zsh" || return 1
            ;;
        "03-install-zinit.sh")
            [ -d "$HOME/.zinit" ] || return 1
            ;;
        "04-install-starship.sh")
            check_installed "starship" || return 1
            ;;
        "05-install-node-nvm.sh")
            [ -d "$HOME/.nvm" ] && [ -s "$HOME/.nvm/nvm.sh" ] || return 1
            ;;
        "06-install-yarn.sh")
            check_installed "yarn" || return 1
            ;;
        "07-install-tools.sh")
            # Check if all tools are installed
            check_installed "zoxide" && \
            check_installed "fzf" && \
            (check_installed "fd" || check_installed "fdfind") && \
            check_installed "bat" && \
            check_installed "lsd" && \
            check_installed "lazygit" || return 1
            ;;
        "08-install-font-jetbrains.sh")
            # Fonts are harder to check, skip for now
            return 1
            ;;
        "09-install-cursor.sh")
            check_installed "cursor" || [ -d "/Applications/Cursor.app" ] || return 1
            ;;
        "10-install-claude.sh")
            check_installed "claude" || [ -d "/Applications/Claude.app" ] || return 1
            ;;
        "11-configure-terminal.sh")
            # Configuration script, always run
            return 1
            ;;
        "12-configure-ssh.sh")
            # Configuration script, always run
            return 1
            ;;
        "13-configure-inotify.sh")
            # Configuration script, always run
            return 1
            ;;
        "14-install-task-master.sh")
            check_installed "task-master-ai" || return 1
            ;;
        "15-configure-cursor.sh")
            # Configuration script, always run
            return 1
            ;;
        "16-install-docker.sh")
            check_installed "docker" || return 1
            ;;
        "17-install-aws-vpn-client.sh")
            check_installed "aws-vpn-client" || return 1
            ;;
        "18-install-aws-cli.sh")
            check_installed "aws" || return 1
            ;;
        "19-configure-aws-sso.sh")
            # Configuration script, always run
            return 1
            ;;
        "20-install-dotnet.sh")
            check_installed "dotnet" || return 1
            ;;
        "21-install-java.sh")
            check_installed "java" || return 1
            ;;
        "22-configure-github-token.sh")
            # Configuration script, always run
            return 1
            ;;
        "23-install-insomnia.sh")
            check_installed "insomnia" || [ -d "/Applications/Insomnia.app" ] || return 1
            ;;
        "24-install-tableplus.sh")
            check_installed "tableplus" || [ -d "/Applications/TablePlus.app" ] || return 1
            ;;
        *)
            # Unknown script, don't skip
            return 1
            ;;
    esac

    return 0
}
