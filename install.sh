#!/bin/bash

# Update and install required packages
echo "Updating package lists..."
sudo apt-get update -y

echo "Installing Node.js and npm..."
# Install Node.js and npm (for Ubuntu/Debian)
sudo apt-get install -y nodejs npm

# Install SQLite (if not already installed)
echo "Installing SQLite..."
sudo apt-get install -y sqlite3

# Install PM2 globally
echo "Installing PM2..."
sudo npm install -g pm2

# Create project directory and navigate into it
PROJECT_DIR="iptv-panel"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Creating project directory: $PROJECT_DIR"
    mkdir "$PROJECT_DIR"
fi
cd "$PROJECT_DIR" || exit

# Initialize npm and install required packages
if [ ! -f "package.json" ]; then
    echo "Initializing npm..."
    npm init -y
fi

echo "Installing required Node.js packages..."
npm install express sqlite3 body-parser node-fetch dotenv

# Create the database file and tables
echo "Setting up the database..."
cat <<EOF > database.js
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('iptv-panel.db');

db.serialize(() => {
    // Create Users Table
    db.run(\`CREATE TABLE IF NOT EXISTS users (
        userId TEXT PRIMARY KEY,
        userCode TEXT NOT NULL,
        loginDetails TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        expiryDate DATETIME,
        deviceDetails TEXT
    )\`);

    // Create Resellers Table
    db.run(\`CREATE TABLE IF NOT EXISTS resellers (
        resellerId TEXT PRIMARY KEY,
        credit INTEGER DEFAULT 0,
        resellerDetails TEXT
    )\`);
});

module.exports = db;
EOF

# Create the main app file
echo "Creating main application file..."
cat <<EOF > app.js
// app.js
const express = require('express');
const bodyParser = require('body-parser');
const db = require('./database');
const fetch = require('node-fetch');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
app.use(bodyParser.json());

// Function to send notifications to Telegram
const sendTelegramNotification = async (message) => {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;
    const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
    await fetch(url, {
        method: 'POST',
        body: JSON.stringify({ chat_id: chatId, text: message }),
        headers: { 'Content-Type': 'application/json' },
    });
};

// Add new user
app.post('/admin/addUser', (req, res) => {
    const { userId, userCode, expiryDate } = req.body;
    db.run(`INSERT INTO users (userId, userCode, expiryDate) VALUES (?, ?, ?)`,
        [userId, userCode, expiryDate], function (err) {
            if (err) {
                return res.status(500).send(err.message);
            }
            sendTelegramNotification(`New user added: ${userId}`);
            res.status(201).send({ userId });
        });
});

// Check user login details
app.get('/admin/userDetails/:userId', (req, res) => {
    const { userId } = req.params;
    db.get(`SELECT * FROM users WHERE userId = ?`, [userId], (err, row) => {
        if (err) {
            return res.status(500).send(err.message);
        }
        res.send(row);
    });
});

// Ban user
app.post('/admin/banUser', (req, res) => {
    const { userId } = req.body;
    db.run(`UPDATE users SET status = 'banned' WHERE userId = ?`, [userId], function (err) {
        if (err) {
            return res.status(500).send(err.message);
        }
        sendTelegramNotification(`User banned: ${userId}`);
        res.send({ message: 'User banned successfully.' });
    });
});

// Unban user
app.post('/admin/unbanUser', (req, res) => {
    const { userId } = req.body;
    db.run(`UPDATE users SET status = 'active' WHERE userId = ?`, [userId], function (err) {
        if (err) {
            return res.status(500).send(err.message);
        }
        sendTelegramNotification(`User unbanned: ${userId}`);
        res.send({ message: 'User unbanned successfully.' });
    });
});

// Renew user subscription
app.post('/admin/renewUser', (req, res) => {
    const { userId, newExpiryDate } = req.body;
    db.run(`UPDATE users SET expiryDate = ? WHERE userId = ?`, [newExpiryDate, userId], function (err) {
        if (err) {
            return res.status(500).send(err.message);
        }
        sendTelegramNotification(`User subscription renewed: ${userId}`);
        res.send({ message: 'User subscription renewed successfully.' });
    });
});

// Add credit for reseller
app.post('/reseller/addCredit', (req, res) => {
    const { resellerId, amount } = req.body;
    db.run(`UPDATE resellers SET credit = credit + ? WHERE resellerId = ?`, [amount, resellerId], function (err) {
        if (err) {
            return res.status(500).send(err.message);
        }
        sendTelegramNotification(`Reseller ${resellerId} credited: ${amount}`);
        res.send({ message: 'Credit added successfully.' });
    });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
EOF

# Create a .env file with specified entries
echo "Creating .env file for configuration..."
cat <<EOF > .env
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id
PORT=3000
EOF

# Start the application with PM2
echo "Starting the application with PM2..."
pm2 start app.js --name iptv-panel

# Save PM2 process list for automatic restart
pm2 save

# Setup PM2 to start on system boot
pm2 startup

# Make the app executable
chmod +x app.js

echo "Installation completed successfully!"
echo "Remember to edit the .env file with your actual Telegram bot token and chat ID."
