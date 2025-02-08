const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');

// Registrace uživatele
router.post('/register', register);

// Přihlášení uživatele
router.post('/login', login);

module.exports = router;
