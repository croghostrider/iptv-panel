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
curl -L -o ~/iptv-panel/public/index.html https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/index.html
curl -L -o ~/iptv-panel/public/style.css https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/style.css
curl -L -o ~/iptv-panel/public/script.js https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/script.js
curl -L -o ~/iptv-panel/public/admin.html https://raw.githubusercontent.com/wayangkulit95/iptv-panel/main/public/admin.html

# Create a valid package.json file
echo '{
  "name": "iptv-panel",
  "version": "1.0.0",
  "description": "An IPTV panel for managing channels, VOD, and series.",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "sqlite3": "^5.0.0",
    "body-parser": "^1.20.0",
    "cors": "^2.8.5"
  }
}' > ~/iptv-panel/package.json

# Create the database file
touch ~/iptv-panel/data.db
echo "Database file created at ~/iptv-panel/data.db."

# Navigate into the project directory
cd ~/iptv-panel || { echo "Directory not found"; exit 1; }

# Install npm dependencies
echo "Installing npm dependencies..."
npm install

# Start the application
echo "Starting the application..."
node app.js &

echo "Installation complete. Access the panel at http://localhost:3000/admin.html."
