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
