#!/bin/bash

# 1. Directory aur Variable define karna
export PTERODACTYL_DIRECTORY=/var/www/pterodactyl
echo "* Using directory: $PTERODACTYL_DIRECTORY"

# 2. Basic Dependencies install karna
echo "* Installing basic dependencies (curl, wget, unzip)..."
sudo apt update
sudo apt install -y curl wget unzip ca-certificates git gnupg zip

# 3. Node.js 22 Repo aur Installation
echo "* Setting up Node.js 22 repository..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

# 4. Blueprint Download aur Extract
echo "* Downloading Blueprint..."
cd $PTERODACTYL_DIRECTORY
wget "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O "release.zip"
unzip -o release.zip

# 5. Yarn aur Node Dependencies install karna
echo "* Installing Yarn and Node dependencies (this might take a minute)..."
npm i -g yarn
yarn install

# 6. .blueprintrc Config file banana
echo "* Configuring .blueprintrc..."
echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc

# 7. Permissions set karna aur Blueprint run karna
echo "* Finalizing installation..."
chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh

# Blueprint execution
bash $PTERODACTYL_DIRECTORY/blueprint.sh

echo "********************************************"
echo "* SUCCESS: Blueprint Installation Finished! *"
echo "********************************************"
