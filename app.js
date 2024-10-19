const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Database Setup
const db = new sqlite3.Database('./data.db');

// Create tables if they don't exist
db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS users (userId TEXT PRIMARY KEY, userCode TEXT NOT NULL, role TEXT, password TEXT)`);
    db.run(`CREATE TABLE IF NOT EXISTS channels (channelId INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, url TEXT)`);
    db.run(`CREATE TABLE IF NOT EXISTS vod (vodId INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, filePath TEXT)`);
    db.run(`CREATE TABLE IF NOT EXISTS series (seriesId INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT)`);
    db.run(`CREATE TABLE IF NOT EXISTS episodes (episodeId INTEGER PRIMARY KEY AUTOINCREMENT, seriesId INTEGER, title TEXT, filePath TEXT, FOREIGN KEY(seriesId) REFERENCES series(seriesId))`);
});

// Secret for JWT
const JWT_SECRET = 'your_jwt_secret';

// User Registration
app.post('/api/users', (req, res) => {
    const { userId, userCode, role, password } = req.body;
    const hashedPassword = bcrypt.hashSync(password, 10);
    
    db.run(`INSERT INTO users (userId, userCode, role, password) VALUES (?, ?, ?, ?)`, [userId, userCode, role, hashedPassword], (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.status(201).json({ userId, userCode, role });
    });
});

// User Login
app.post('/admin/login', (req, res) => {
    const { userId, password } = req.body;
    db.get(`SELECT * FROM users WHERE userId = ?`, [userId], (err, user) => {
        if (err || !user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        if (!bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        const token = jwt.sign({ userId: user.userId, role: user.role }, JWT_SECRET, { expiresIn: '1h' });
        res.json({ token });
    });
});

// Middleware to authenticate JWT
const authenticateJWT = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (token) {
        jwt.verify(token, JWT_SECRET, (err, user) => {
            if (err) {
                return res.sendStatus(403);
            }
            req.user = user;
            next();
        });
    } else {
        res.sendStatus(401);
    }
};

// Protected Routes (requires JWT)
app.use(authenticateJWT);

// Channel Management
app.post('/api/channels', (req, res) => {
    const { name, url } = req.body;
    db.run(`INSERT INTO channels (name, url) VALUES (?, ?)`, [name, url], (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.status(201).json({ name, url });
    });
});

app.get('/api/channels', (req, res) => {
    db.all(`SELECT * FROM channels`, [], (err, rows) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

// VOD Management
app.post('/api/vod', (req, res) => {
    const { title, description, filePath } = req.body;
    db.run(`INSERT INTO vod (title, description, filePath) VALUES (?, ?, ?)`, [title, description, filePath], (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.status(201).json({ title, description, filePath });
    });
});

app.get('/api/vod', (req, res) => {
    db.all(`SELECT * FROM vod`, [], (err, rows) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

// Series Management
app.post('/api/series', (req, res) => {
    const { title, description } = req.body;
    db.run(`INSERT INTO series (title, description) VALUES (?, ?)`, [title, description], (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.status(201).json({ title, description });
    });
});

app.get('/api/series', (req, res) => {
    db.all(`SELECT * FROM series`, [], (err, rows) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

// Episode Management
app.post('/api/episodes', (req, res) => {
    const { seriesId, title, filePath } = req.body;
    db.run(`INSERT INTO episodes (seriesId, title, filePath) VALUES (?, ?, ?)`, [seriesId, title, filePath], (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.status(201).json({ seriesId, title, filePath });
    });
});

app.get('/api/episodes', (req, res) => {
    db.all(`SELECT * FROM episodes`, [], (err, rows) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

// Start Server
app.listen(port, () => {
    console.log(`Server is running on http://localhost:${port}`);
});
