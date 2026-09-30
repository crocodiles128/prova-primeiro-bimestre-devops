const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.APP_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function initDb() {
  const queryText = `
    CREATE TABLE IF NOT EXISTS reservas (
      id SERIAL PRIMARY KEY,
      cliente VARCHAR(255) NOT NULL,
      data VARCHAR(50) NOT NULL,
      status VARCHAR(20) NOT NULL DEFAULT 'ativa'
    );
  `;

  try {
    await pool.query(queryText);
  } catch (error) {
    console.error('Erro ao inicializar tabela reservas:', error.message);
    throw error;
  }
}

async function query(sql, params = []) {
  return pool.query(sql, params);
}

module.exports = {
  initDb,
  query,
};
