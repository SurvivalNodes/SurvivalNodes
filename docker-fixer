#!/bin/bash

# Detect OS
source /etc/os-release

echo "Detected OS: $NAME $VERSION_CODENAME"
# Set version based on OS
if [[ "$ID" == "ubuntu" ]]; then
    VERSION="1.7.28-1~ubuntu.$VERSION_CODENAME"
elif [[ "$ID" == "debian" ]]; then
    VERSION="1.7.28-1~debian.$VERSION_CODENAME"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "Installing containerd version: $VERSION"
sudo apt update
sudo apt install -y --allow-downgrades --allow-change-held-packages containerd.io=$VERSION
