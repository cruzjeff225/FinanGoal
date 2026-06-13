const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth');

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

// @route   PUT api/auth/profile
// @desc    Update user profile (name and/or email)
// @access  Private
router.put('/profile', auth, async (req, res) => {
  const { name, email } = req.body;
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado.' });
    }
    
    if (email && email.toLowerCase() !== user.email) {
      // Comprobar si el correo ya existe
      const emailExists = await User.findOne({ email: email.toLowerCase() });
      if (emailExists) {
        return res.status(400).json({ message: 'Este correo electrónico ya está registrado.' });
      }
      user.email = email.toLowerCase();
    }
    
    if (name) {
      user.name = name;
    }
    
    await user.save();
    res.json({
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al actualizar perfil.' });
  }
});

// @route   PUT api/auth/password
// @desc    Update user password
// @access  Private
router.put('/password', auth, async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  try {
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Por favor, proporcione todos los campos.' });
    }
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado.' });
    }
    
    const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isMatch) {
      return res.status(400).json({ message: 'La contraseña actual es incorrecta.' });
    }
    
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash(newPassword, salt);
    await user.save();
    
    res.json({ message: 'Contraseña actualizada correctamente.' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al actualizar contraseña.' });
  }
});

module.exports = router;
