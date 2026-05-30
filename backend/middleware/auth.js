const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
  // Obtener el token de la cabecera Authorization
  const authHeader = req.header('Authorization');

  if (!authHeader) {
    return res.status(401).json({ message: 'Acceso denegado. No se proporcionó token.' });
  }

  // El token normalmente viene formateado como "Bearer <token>"
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(400).json({ message: 'Formato de token inválido.' });
  }

  const token = parts[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // Añadir el ID de usuario decodificado a la petición para usarlo en las rutas
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token inválido o expirado.' });
  }
};
