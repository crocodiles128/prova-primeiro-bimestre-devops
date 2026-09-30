require('dotenv').config({ path: require('path').resolve(__dirname, '..', '..', '.env') });

const express = require('express');
const healthRoutes = require('./routes/health');
const reservasRoutes = require('./routes/reservas');
const { initDb } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use('/', healthRoutes);
app.use('/reservas', reservasRoutes);

async function startServer() {
  try {
    await initDb();
    app.listen(PORT, () => {
      console.log(`API rodando na porta ${PORT}`);
    });
  } catch (error) {
    console.error('Falha ao iniciar a API:', error.message);
    process.exit(1);
  }
}

startServer();
