const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors()); // Enable CORS

const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_DATABASE,
});

// API Endpoints for Movies
app.get('/movies', async (req, res) => {
    try {
        const { genre, rating } = req.query;
        let query = 'SELECT * FROM movies';
        const values = [];
        let conditions = [];

        if (genre) {
            conditions.push('genre = $1');
            values.push(genre);
        }
        if (rating) {
            conditions.push('rating >= $' + (values.length + 1));
            values.push(rating);
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        query += ' ORDER BY rating DESC';

        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.post('/movies', async (req, res) => {
    const { title, genre, rating, reviewed, review_text } = req.body;
    try {
        if (!title) {
            return res.status(400).json({ error: 'Title is required' });
        }
        if (rating && (rating < 0 || rating > 10)) {
            return res.status(400).json({ error: 'Rating must be between 0 and 10' });
        }
        const result = await pool.query(
            'INSERT INTO movies (title, genre, rating, reviewed, review_text) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [title, genre || null, rating || null, reviewed || false, review_text || null]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.put('/movies/:id', async (req, res) => {
    const { id } = req.params;
    const { title, genre, rating, reviewed, review_text } = req.body;
    try {
        if (rating && (rating < 0 || rating > 10)) {
            return res.status(400).json({ error: 'Rating must be between 0 and 10' });
        }
        const result = await pool.query(
            'UPDATE movies SET title = $1, genre = $2, rating = $3, reviewed = $4, review_text = $5 WHERE id = $6 RETURNING *',
            [title, genre || null, rating || null, reviewed || false, review_text || null, id]
        );
        if (result.rowCount === 0) return res.status(404).send('Movie not found');
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// API Endpoints for Inventory
app.get('/inventory', async (req, res) => {
    try {
        const { lowStock } = req.query;
        let query = 'SELECT * FROM inventory';
        const values = [];
        if (lowStock === 'true') {
            query += ' WHERE quantity <= reorder_level';
        }
        const result = await pool.query(query, values);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.post('/inventory', async (req, res) => {
    const { item_name, quantity, supplier, reorder_level } = req.body;
    try {
        if (!item_name || quantity == null || reorder_level == null) {
            return res.status(400).json({ error: 'Item name, quantity, and reorder level are required' });
        }
        if (quantity < 0 || reorder_level < 0) {
            return res.status(400).json({ error: 'Quantity and reorder level cannot be negative' });
        }
        const result = await pool.query(
            'INSERT INTO inventory (item_name, quantity, supplier, reorder_level) VALUES ($1, $2, $3, $4) RETURNING *',
            [item_name, quantity, supplier || null, reorder_level]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.put('/inventory/:id', async (req, res) => {
    const { id } = req.params;
    const { item_name, quantity, supplier, reorder_level } = req.body;
    try {
        if (quantity != null && quantity < 0 || reorder_level != null && reorder_level < 0) {
            return res.status(400).json({ error: 'Quantity and reorder level cannot be negative' });
        }
        const result = await pool.query(
            'UPDATE inventory SET item_name = $1, quantity = $2, supplier = $3, reorder_level = $4 WHERE id = $5 RETURNING *',
            [item_name, quantity, supplier || null, reorder_level, id]
        );
        if (result.rowCount === 0) return res.status(404).send('Inventory item not found');
        res.json(result.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.delete('/inventory/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const result = await pool.query('DELETE FROM inventory WHERE id = $1', [id]);
        if (result.rowCount === 0) return res.status(404).send('Inventory item not found');
        res.status(204).send();
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error', details: err.message });
    }
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});