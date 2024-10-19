#!/bin/bash

# Update the package list and upgrade all packages
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install Node.js and npm
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs

# Install SQLite3
echo "Installing SQLite3..."
sudo apt install -y sqlite3

# Install Git
echo "Installing Git..."
sudo apt install -y git

# Create a directory for the IPTV panel
echo "Creating directory for IPTV panel..."
mkdir -p ~/iptv-panel

# Download the IPTV panel files using curl
echo "Downloading IPTV panel files..."
curl -L -o ~/iptv-panel/app.js https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/app.js
curl -L -o ~/iptv-panel/package.json https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/package.json
curl -L -o ~/iptv-panel/public/index.html https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/index.html
curl -L -o ~/iptv-panel/public/style.css https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/style.css
curl -L -o ~/iptv-panel/public/script.js https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/script.js
curl -L -o ~/iptv-panel/public/admin.html https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/admin.html

# Create the database file
touch ~/iptv-panel/data.db
echo "Database file created at ~/iptv-panel/data.db."

# Navigate into the project directory
cd ~/iptv-panel || { echo "Directory not found"; exit 1; }

# Install npm dependencies
echo "Installing npm dependencies..."
npm install express sqlite3 body-parser cors

# Start the application
echo "Starting the application..."
node app.js &

echo "Installation complete. Access the panel at http://localhost:3000/admin.html."
