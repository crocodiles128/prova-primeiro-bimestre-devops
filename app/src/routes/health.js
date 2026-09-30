const express = require('express');
const router = express.Router();

router.get('/health', async (req, res) => {
  res.status(200).json({
    status: 'ok',
    uptime: process.uptime(),
  });
});

module.exports = router;
