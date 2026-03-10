module.exports = (err, req, res, _next) => {
  console.error('Error:', err.message);

  const status = err.status || 500;
  const message = err.message || 'Sunucu hatası';

  // API isteklerinde JSON dön
  if (req.originalUrl.startsWith('/api')) {
    return res.status(status).json({ error: message });
  }

  // Web isteklerinde hata sayfası göster
  res.status(status).render('error', {
    layout: false,
    title: 'Hata',
    status,
    message,
  });
};
