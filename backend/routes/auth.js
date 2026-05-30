const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// @route   POST api/auth/register
// @desc    Register a user
// @access  Public
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;

  try {
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Por favor, proporcione todos los campos.' });
    }

    // Comprobar si el usuario existe
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'Este correo electrónico ya está registrado.' });
    }

    // Crear el nuevo usuario
    user = new User({
      name,
      email,
      passwordHash: password // Se hasheará abajo
    });

    // Encriptar contraseña
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(password, salt);

    await user.save();

    // Crear token JWT
    const payload = {
      id: user.id
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '30d' }, // Expira en 30 días
      (err, token) => {
        if (err) throw err;
        res.json({
          token,
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        });
      }
    );

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al registrarse.' });
  }
});

// @route   POST api/auth/login
// @desc    Authenticate user & get token
// @access  Public
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    if (!email || !password) {
      return res.status(400).json({ message: 'Por favor, introduzca correo y contraseña.' });
    }

    // Comprobar si el usuario existe
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Credenciales inválidas. Correo no encontrado.' });
    }

    // Validar contraseña
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ message: 'Credenciales inválidas. Contraseña incorrecta.' });
    }

    // Crear token JWT
    const payload = {
      id: user.id
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '30d' },
      (err, token) => {
        if (err) throw err;
        res.json({
          token,
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        });
      }
    );

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al iniciar sesión.' });
  }
});

module.exports = router;
