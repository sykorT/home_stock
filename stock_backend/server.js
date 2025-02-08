require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json()); // Middleware pro JSON

// Načtení routes
const itemsRoutes = require('./routes/items');
app.use('/api/items', itemsRoutes);

// Testovací endpoint
app.get('/', (req, res) => {
    res.send('Home Stock API is running 🚀');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
});
