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

# Validate required AWS SSO variables
if [ -z "$AWS_SSO_START_URL" ]; then
    echo "❌ AWS_SSO_START_URL is required in .env file"
    exit 1
fi

if [ -z "$AWS_SSO_REGION" ]; then
    echo "❌ AWS_SSO_REGION is required in .env file"
    exit 1
fi

# Use first account as default if available
AWS_DEFAULT_ACCOUNT_ID="${AWS_ACCOUNT_1_ID:-}"
AWS_DEFAULT_ROLE="${AWS_ACCOUNT_1_ROLE:-}"
AWS_DEFAULT_REGION="${AWS_SSO_REGION:-us-east-1}"

if [ -z "$AWS_DEFAULT_ACCOUNT_ID" ] || [ -z "$AWS_DEFAULT_ROLE" ]; then
    echo "⚠️  AWS_ACCOUNT_1_ID and AWS_ACCOUNT_1_ROLE not set in .env"
    echo "   Using minimal configuration. You can add accounts later."
    AWS_DEFAULT_ACCOUNT_ID=""
    AWS_DEFAULT_ROLE=""
fi

echo "=============================================="
echo "======= [20] CONFIGURING AWS SSO ============="
echo "=============================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please run 17-install-aws-cli.sh first."
    exit 1
fi

echo "Configuring AWS SSO..."
echo ""

# Check if already configured
if [ -f "$HOME/.aws/config" ] && grep -q "\[profile default\]" "$HOME/.aws/config" && grep -q "sso_start_url" "$HOME/.aws/config"; then
    echo "⚠️  AWS SSO appears to be already configured."
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuration skipped."
        exit 0
    fi
    # Backup existing config
    if [ -f "$HOME/.aws/config" ]; then
        cp "$HOME/.aws/config" "$HOME/.aws/config.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✓ Existing config backed up"
    fi
fi

# Create .aws directory if it doesn't exist
mkdir -p "$HOME/.aws"

# Configure AWS SSO
echo "Setting up AWS SSO configuration..."

# Create config file with SSO session
cat > "$HOME/.aws/config" << EOF
[sso-session default]
sso_start_url = $AWS_SSO_START_URL
sso_region = $AWS_SSO_REGION
EOF

# Add default profile if account and role are configured
if [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ -n "$AWS_DEFAULT_ROLE" ]; then
    cat >> "$HOME/.aws/config" << EOF

[default]
sso_session = default
sso_account_id = $AWS_DEFAULT_ACCOUNT_ID
sso_role_name = $AWS_DEFAULT_ROLE
region = $AWS_DEFAULT_REGION
output = json
EOF
fi

# Add additional accounts from .env
account_num=1
while true; do
    account_id_var="AWS_ACCOUNT_${account_num}_ID"
    role_var="AWS_ACCOUNT_${account_num}_ROLE"
    profile_var="AWS_ACCOUNT_${account_num}_PROFILE"

    account_id="${!account_id_var}"
    role="${!role_var}"
    profile="${!profile_var}"

    if [ -z "$account_id" ] || [ -z "$role" ]; then
        break
    fi

    # Use profile name or default to account number
    profile_name="${profile:-account-${account_num}}"

    # Skip if this is account 1 and we already added it as default
    if [ "$account_num" -eq 1 ] && [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ "$account_id" = "$AWS_DEFAULT_ACCOUNT_ID" ]; then
        account_num=$((account_num + 1))
        continue
    fi

    cat >> "$HOME/.aws/config" << EOF

[profile $profile_name]
sso_session = default
sso_account_id = $account_id
sso_role_name = $role
region = $AWS_DEFAULT_REGION
output = json
EOF

    account_num=$((account_num + 1))
done

echo "✓ AWS SSO configuration created"
echo ""
echo "Configuration details:"
echo "  - SSO Start URL: $AWS_SSO_START_URL"
echo "  - SSO Region: $AWS_SSO_REGION"
if [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ -n "$AWS_DEFAULT_ROLE" ]; then
    echo "  - Default Account: $AWS_DEFAULT_ACCOUNT_ID"
    echo "  - Default Role: $AWS_DEFAULT_ROLE"
fi
echo "  - Default Region: $AWS_DEFAULT_REGION"
echo "  - Output Format: json"
echo ""

echo "=============================================="
echo "============== [20] DONE ===================="
echo "=============================================="
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Login to AWS SSO:"
echo "   aws sso login"
echo ""
echo "2. Test the configuration:"
echo "   aws sts get-caller-identity"
echo ""
echo "🎉 AWS SSO configuration complete!"
