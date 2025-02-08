const express = require('express');
const router = express.Router();
const pool = require('../db');
const authenticate = require('../middleware/authMiddleware');

// Získání všech položek (nechráněný)
router.get('/', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM items');
        res.json(result.rows);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// Přidání nové položky (chráněný)
router.post('/', authenticate, async (req, res) => {
    const { stock_id, barcode, quantity, expiration_date } = req.body;

    try {
        const result = await pool.query(
            'INSERT INTO items (stock_id, barcode, quantity, expiration_date) VALUES ($1, $2, $3, $4) RETURNING *',
            [stock_id, barcode, quantity, expiration_date]
        );
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// Aktualizace položky (chráněný)
router.put('/:id', authenticate, async (req, res) => {
    const { id } = req.params;
    const { stock_id, barcode, quantity, expiration_date } = req.body;

    try {
        const result = await pool.query(
            'UPDATE items SET stock_id = $1, barcode = $2, quantity = $3, expiration_date = $4 WHERE id = $5 RETURNING *',
            [stock_id, barcode, quantity, expiration_date, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('Item not found');
        }

        res.json(result.rows[0]);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

// Smazání položky (chráněný)
router.delete('/:id', authenticate, async (req, res) => {
    const { id } = req.params;

    try {
        const result = await pool.query(
            'DELETE FROM items WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('Item not found');
        }

        res.json({ message: 'Item deleted' });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server error');
    }
});

module.exports = router;
