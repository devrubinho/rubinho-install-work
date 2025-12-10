#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [13] CONFIGURING INOTIFY ==========="
echo "=============================================="

echo "Setting inotify max_user_watches..."
sudo sysctl fs.inotify.max_user_watches=524288

echo "Making inotify setting persistent..."
if ! grep -q "fs.inotify.max_user_watches=524288" /etc/sysctl.conf; then
  echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
fi

echo "Applying sysctl changes..."
sudo sysctl -p

echo "Verifying setting..."
cat /proc/sys/fs/inotify/max_user_watches

echo "=============================================="
echo "============== [13] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 14-install-task-master.sh"
