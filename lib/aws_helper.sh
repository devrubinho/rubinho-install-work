#!/usr/bin/env bash

#
# AWS Helper Module
#
# Provides functions to get AWS environment variables for .env file
# and check if AWS account variables exist.
#
# Usage:
#   source lib/aws_helper.sh
#   get_aws_env_variables
#   has_aws_account_variables ".env"
#

set -eo pipefail

# ────────────────────────────────────────────────────────────────
# Extract Profile Data (internal function)
# ────────────────────────────────────────────────────────────────

_extract_profile_data() {
    local profile_name="$1"
    local config_file="${2:-$HOME/.aws/config}"
    local account_id=""
    local role=""
    local region=""
    local in_profile=false
    
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^\[profile\ $profile_name\]$ ]] || [[ "$line" =~ ^\[default\]$ && "$profile_name" == "default" ]]; then
            in_profile=true
            continue
        fi
        if [[ "$line" =~ ^\[ ]] && [ "$in_profile" = true ]; then
            break
        fi
        if [ "$in_profile" = true ]; then
            if [[ "$line" =~ sso_account_id ]]; then
                account_id=$(echo "$line" | awk '{print $3}')
            elif [[ "$line" =~ sso_role_name ]]; then
                role=$(echo "$line" | awk '{print $3}')
            elif [[ "$line" =~ ^region ]]; then
                region=$(echo "$line" | awk '{print $3}')
            fi
        fi
    done < "$config_file"
    
    echo "$profile_name|$account_id|$role|$region"
}

# ────────────────────────────────────────────────────────────────
# Get AWS SSO Start URL
# ────────────────────────────────────────────────────────────────

get_aws_sso_start_url() {
    local config_file="$HOME/.aws/config"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Try sso-session first
    local sso_url
    sso_url=$(awk '/^\[sso-session /,/^\[/ {
        if (/sso_start_url/) {
            gsub(/sso_start_url[[:space:]]*=[[:space:]]*/, "", $0)
            print $0
            exit
        }
    }' "$config_file")
    
    # If not found, try default profile
    if [ -z "$sso_url" ]; then
        sso_url=$(awk '/^\[default\]/,/^\[/ {
            if (/sso_start_url/) {
                gsub(/sso_start_url[[:space:]]*=[[:space:]]*/, "", $0)
                print $0
                exit
            }
        }' "$config_file")
    fi
    
    echo "$sso_url"
}

# ────────────────────────────────────────────────────────────────
# Get AWS SSO Region
# ────────────────────────────────────────────────────────────────

get_aws_sso_region() {
    local config_file="$HOME/.aws/config"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Try sso-session first
    local sso_region
    sso_region=$(awk '/^\[sso-session /,/^\[/ {
        if (/sso_region/) {
            gsub(/sso_region[[:space:]]*=[[:space:]]*/, "", $0)
            print $0
            exit
        }
    }' "$config_file")
    
    # If not found, try default profile
    if [ -z "$sso_region" ]; then
        sso_region=$(awk '/^\[default\]/,/^\[/ {
            if (/sso_region/) {
                gsub(/sso_region[[:space:]]*=[[:space:]]*/, "", $0)
                print $0
                exit
            }
            if (/^region/) {
                gsub(/region[[:space:]]*=[[:space:]]*/, "", $0)
                print $0
                exit
            }
        }' "$config_file")
    fi
    
    echo "$sso_region"
}

# ────────────────────────────────────────────────────────────────
# Get AWS Environment Variables for .env file
# ────────────────────────────────────────────────────────────────

get_aws_env_variables() {
    local config_file="$HOME/.aws/config"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Get SSO info
    local sso_start_url
    local sso_region
    sso_start_url=$(get_aws_sso_start_url)
    sso_region=$(get_aws_sso_region)
    
    # Output SSO variables
    if [ -n "$sso_start_url" ]; then
        echo "AWS_SSO_START_URL=$sso_start_url"
    fi
    if [ -n "$sso_region" ]; then
        echo "AWS_SSO_REGION=$sso_region"
    fi
    if [ -n "$sso_start_url" ] || [ -n "$sso_region" ]; then
        echo ""
    fi
    
    # Collect profiles
    local profiles_array=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[profile\ (.+)\]$ ]]; then
            profiles_array+=("${BASH_REMATCH[1]}")
        fi
    done < <(grep -E '^\[profile ' "$config_file")
    
    # Process profiles
    local account_num=1
    
    # Default profile first
    if grep -q "^\[default\]" "$config_file"; then
        local profile_data
        profile_data=$(_extract_profile_data "default" "$config_file")
        IFS='|' read -r profile_name account_id role region <<< "$profile_data"
        
        if [ -n "$account_id" ] && [ -n "$role" ]; then
            echo "AWS_ACCOUNT_${account_num}_ID=$account_id"
            echo "AWS_ACCOUNT_${account_num}_ROLE=$role"
            echo "AWS_ACCOUNT_${account_num}_PROFILE=default"
            echo ""
            account_num=$((account_num + 1))
        fi
    fi
    
    # Other profiles
    for profile in "${profiles_array[@]}"; do
        local profile_data
        profile_data=$(_extract_profile_data "$profile" "$config_file")
        IFS='|' read -r profile_name account_id role region <<< "$profile_data"
        
        if [ -n "$account_id" ] && [ -n "$role" ]; then
            echo "AWS_ACCOUNT_${account_num}_ID=$account_id"
            echo "AWS_ACCOUNT_${account_num}_ROLE=$role"
            echo "AWS_ACCOUNT_${account_num}_PROFILE=$profile_name"
            echo ""
            account_num=$((account_num + 1))
        fi
    done
}

# ────────────────────────────────────────────────────────────────
# Check if AWS Account Variables Exist in .env
# ────────────────────────────────────────────────────────────────

has_aws_account_variables() {
    local env_file="${1:-}"
    
    if [ -z "$env_file" ] || [ ! -f "$env_file" ]; then
        return 1
    fi
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check if this line matches AWS_ACCOUNT_*_ID pattern
        if [[ "$line" =~ ^[[:space:]]*AWS_ACCOUNT_[0-9]+_ID[[:space:]]*= ]]; then
            return 0
        fi
    done < "$env_file"
    
    return 1
}

# Export functions for use in other scripts
export -f get_aws_sso_start_url
export -f get_aws_sso_region
export -f get_aws_env_variables
export -f has_aws_account_variables
