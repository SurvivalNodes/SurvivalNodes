#!/bin/bash

# ===============================
#   🌟 SUNNYGAMINGPE INSTALLER 🌟
# ===============================

clear
echo -e "\e[1;36m"
echo "==============================================="
echo "   🚀 SUNNYGAMINGPE BLUEPRINT INSTALLER 🚀"
echo "==============================================="
echo -e "\e[0m"

# Set directory
export PTERODACTYL_DIRECTORY=/var/www/pterodactyl

log() {
    echo -e "\e[1;32m[✔] $1\e[0m"
}

step() {
    echo -e "\e[1;34m[➤] $1\e[0m"
}

error() {
    echo -e "\e[1;31m[✘] $1\e[0m"
}

# ===============================
# STEP 1: UPDATE SYSTEM
# ===============================
step "Updating packages..."
sudo apt update -y || error "Failed to update"

# ===============================
# STEP 2: INSTALL DEPENDENCIES
# ===============================
step "Installing dependencies..."
sudo apt install -y curl wget unzip ca-certificates git gnupg zip || error "Dependency install failed"

# ===============================
# STEP 3: GO TO PANEL DIR
# ===============================
step "Navigating to Pterodactyl directory..."
cd $PTERODACTYL_DIRECTORY || exit

# ===============================
# STEP 4: DOWNLOAD BLUEPRINT
# ===============================
step "Downloading Blueprint Framework..."
wget "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O release.zip

step "Extracting Blueprint..."
unzip -o release.zip

# ===============================
# STEP 5: INSTALL NODEJS
# ===============================
step "Setting up Node.js repo..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt update
step "Installing Node.js..."
sudo apt install -y nodejs

# ===============================
# STEP 6: INSTALL YARN
# ===============================
step "Installing Yarn & Node modules..."
npm i -g yarn
yarn install --network-timeout 100000

# ===============================
# STEP 7: CONFIGURE BLUEPRINT
# ===============================
step "Configuring Blueprint..."
echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc

# ===============================
# STEP 8: RUN BLUEPRINT
# ===============================
step "Running Blueprint setup..."
chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh
bash $PTERODACTYL_DIRECTORY/blueprint.sh

# ===============================
# STEP 9: INSTALL CUSTOM BLUEPRINTS
# ===============================
step "Downloading Blueprints Addon ..."
cd $PTERODACTYL_DIRECTORY
wget https://github.com/SurvivalNodes/SurvivalNodes/releases/download/Blueprints/Blueprint.zip -O Blueprint.zip

step "Extracting Blueprints Addons..."
unzip -o Blueprint.zip

step "Installing all Nebula Version Manager And Many More files..."
blueprint -install *.blueprint

# ===============================
# DONE
# ===============================
echo -e "\e[1;36m"
echo "==============================================="
echo "     ✅ INSTALLATION COMPLETED SUCCESSFULLY"
echo "        💙 POWERED BY SUNNYGAMINGPE 💙"
echo "==============================================="
echo -e "\e[0m"
