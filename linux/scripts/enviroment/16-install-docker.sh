#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [16] INSTALLING DOCKER ============="
echo "=============================================="

echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y

echo "Removing old Docker installations..."
sudo apt remove -y docker docker-engine docker.io containerd runc || true

echo "Installing required dependencies..."
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG Key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "Adding Docker Repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

echo "Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Testing Docker..."
sudo docker run hello-world || true

echo "Adding current user to docker group..."
sudo usermod -aG docker $USER

echo "=============================================="
echo "============== [16] DONE ===================="
echo "=============================================="
echo "⚠️  Logout/Login required to use Docker without sudo"
echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo "=============================================="
echo "All scripts have been executed successfully!"
echo "Restart the terminal to apply all changes."

