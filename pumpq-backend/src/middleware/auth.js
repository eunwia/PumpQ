const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res
      .status(401)
      .json({ success: false, data: null, message: 'Missing or invalid token' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = Number(payload.sub);
    next();
  } catch {
    return res
      .status(401)
      .json({ success: false, data: null, message: 'Token expired or invalid' });
  }
}

module.exports = { requireAuth };