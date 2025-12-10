#!/usr/bin/env bash

# Function to check if apt is locked
check_apt_lock() {
    local lock_files=(
        "/var/lib/apt/lists/lock"
        "/var/lib/dpkg/lock"
        "/var/cache/apt/archives/lock"
    )

    local locked=false
    local lock_file=""
    local lock_pid=""

    for lock in "${lock_files[@]}"; do
        if [ -f "$lock" ]; then
            # Try to get the PID holding the lock
            lock_pid=$(lsof "$lock" 2>/dev/null | awk 'NR==2 {print $2}' || echo "")
            if [ -n "$lock_pid" ]; then
                locked=true
                lock_file="$lock"
                break
            fi
        fi
    done

    if [ "$locked" = true ]; then
        return 0  # Locked
    else
        return 1  # Not locked
    fi
}

# Function to wait for apt lock to be released
wait_for_apt_lock() {
    local max_wait=${1:-60}  # Default 60 seconds
    local waited=0
    local check_interval=2

    echo "⏳ Waiting for apt lock to be released..."

    while [ $waited -lt $max_wait ]; do
        if ! check_apt_lock; then
            echo "✓ Apt lock released"
            return 0
        fi

        sleep $check_interval
        waited=$((waited + check_interval))
        echo "  Still waiting... (${waited}s/${max_wait}s)"
    done

    return 1  # Timeout
}

# Function to handle apt lock error with user interaction
handle_apt_lock_error() {
    if ! check_apt_lock; then
        return 0  # No lock, continue
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  APT is currently locked"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Find which process is holding the lock
    local lock_files=(
        "/var/lib/apt/lists/lock"
        "/var/lib/dpkg/lock"
        "/var/cache/apt/archives/lock"
    )

    local lock_info=""
    local pid=""
    local lock_file=""

    for lock in "${lock_files[@]}"; do
        if [ -f "$lock" ]; then
            # Try multiple methods to get PID
            pid=$(lsof "$lock" 2>/dev/null | awk 'NR==2 {print $2}' || echo "")
            if [ -z "$pid" ]; then
                # Alternative: check fuser
                pid=$(fuser "$lock" 2>/dev/null | awk '{print $1}' | head -1 || echo "")
            fi
            if [ -n "$pid" ]; then
                local process=$(ps -p "$pid" -o comm= 2>/dev/null | head -1 || echo "unknown")
                lock_file="$lock"
                lock_info="Lock file: $lock\nProcess: $process (PID: $pid)"
                break
            fi
        fi
    done

    if [ -n "$lock_info" ]; then
        echo -e "$lock_info"
        echo ""
    fi

    echo "Options:"
    echo "  1. Wait for the lock to be released automatically"
    echo "  2. Show process details and wait"
    echo "  3. Exit and fix manually"
    echo ""

    if [ -t 0 ]; then  # Interactive mode
        read -p "Choose an option [1-3]: " -n 1 -r
        echo ""

        case $REPLY in
            1)
                if wait_for_apt_lock 120; then
                    return 0
                else
                    echo "❌ Timeout waiting for apt lock"
                    return 1
                fi
                ;;
            2)
                if [ -n "$pid" ] && [ "$pid" != "unknown" ]; then
                    echo ""
                    echo "Process details:"
                    ps -p "$pid" -f 2>/dev/null || echo "Process not found (may have finished)"
                    echo ""
                else
                    echo ""
                    echo "Could not determine which process is holding the lock"
                    echo ""
                fi
                if wait_for_apt_lock 120; then
                    return 0
                else
                    echo "❌ Timeout waiting for apt lock"
                    return 1
                fi
                ;;
            3)
                echo ""
                echo "To fix manually:"
                if [ -n "$pid" ] && [ "$pid" != "unknown" ]; then
                    echo "  1. Wait for the other apt process to finish"
                    echo "  2. Or kill the process: sudo kill $pid"
                    echo "  3. Then run the installation again"
                else
                    echo "  1. Check for running apt processes: ps aux | grep apt"
                    echo "  2. Wait for them to finish or kill if needed"
                    echo "  3. Remove lock files manually (NOT RECOMMENDED):"
                    echo "     sudo rm /var/lib/apt/lists/lock"
                    echo "     sudo rm /var/lib/dpkg/lock"
                    echo "  4. Then run the installation again"
                fi
                echo ""
                return 1
                ;;
            *)
                echo "Invalid option. Exiting..."
                return 1
                ;;
        esac
    else
        # Non-interactive mode - just wait
        echo "Non-interactive mode: waiting for lock..."
        if wait_for_apt_lock 120; then
            return 0
        else
            echo "❌ Timeout waiting for apt lock"
            return 1
        fi
    fi
}

# Function to safely run apt commands with lock checking
safe_apt_update() {
    if ! handle_apt_lock_error; then
        return 1
    fi

    sudo apt update -y
}

safe_apt_install() {
    local packages="$@"

    if ! handle_apt_lock_error; then
        return 1
    fi

    sudo apt install -y $packages
}
