const jwt = require('jsonwebtoken');

function requireStaffAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ success: false, data: null, message: 'Missing or invalid token' });
  }
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.type !== 'staff') throw new Error('not staff');
    req.staffId = Number(payload.sub);
    next();
  } catch {
    return res.status(401).json({ success: false, data: null, message: 'Token expired or invalid' });
  }
}

module.exports = { requireStaffAuth };