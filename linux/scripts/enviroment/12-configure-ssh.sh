#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [12] CONFIGURING SSH =============="
echo "=============================================="

echo "Installing OpenSSH and xclip..."
sudo apt update -y
sudo apt install -y openssh-client xclip

# Validate email from .env
if [ -z "$GIT_USER_EMAIL" ]; then
    echo "❌ GIT_USER_EMAIL is required in .env file"
    exit 1
fi

echo "Generating SSH key with email: $GIT_USER_EMAIL"
if [ ! -f ~/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f ~/.ssh/id_ed25519 -N ""
else
  echo "SSH key already exists."
fi

echo "Starting SSH agent..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "Setting correct permissions..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

echo "Copying public key to clipboard..."
cat ~/.ssh/id_ed25519.pub | xclip -sel clip

echo "=============================================="
echo "============== [12] DONE ===================="
echo "=============================================="
echo "✅ SSH public key copied to clipboard!"
echo "   Go to GitHub/GitLab Settings → SSH Keys and paste it."
echo "▶ Next, run: bash 13-configure-inotify.sh"

