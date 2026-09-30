const express = require('express');
const router = express.Router();
const { query } = require('../db');

router.post('/', async (req, res) => {
  const { cliente, data } = req.body || {};

  if (!cliente) {
    return res.status(400).json({ error: 'Campo cliente é obrigatório.' });
  }

  if (!data) {
    return res.status(400).json({ error: 'Campo data é obrigatório.' });
  }

  try {
    const result = await query(
      'INSERT INTO reservas (cliente, data) VALUES ($1, $2) RETURNING *',
      [cliente, data]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Erro ao criar reserva:', error.message);
    return res.status(500).json({ error: 'Erro interno ao criar reserva.' });
  }
});

router.get('/', async (req, res) => {
  try {
    const result = await query('SELECT * FROM reservas ORDER BY id ASC');
    return res.status(200).json(result.rows);
  } catch (error) {
    console.error('Erro ao listar reservas:', error.message);
    return res.status(500).json({ error: 'Erro interno ao listar reservas.' });
  }
});

router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await query('SELECT * FROM reservas WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reserva não encontrada.' });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Erro ao buscar reserva:', error.message);
    return res.status(500).json({ error: 'Erro interno ao buscar reserva.' });
  }
});

router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { cliente, data, status } = req.body || {};

  try {
    const existing = await query('SELECT * FROM reservas WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Reserva não encontrada.' });
    }

    const updateCliente = cliente ?? existing.rows[0].cliente;
    const updateData = data ?? existing.rows[0].data;
    const updateStatus = status ?? existing.rows[0].status;

    const result = await query(
      'UPDATE reservas SET cliente = $1, data = $2, status = $3 WHERE id = $4 RETURNING *',
      [updateCliente, updateData, updateStatus, id]
    );

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Erro ao atualizar reserva:', error.message);
    return res.status(500).json({ error: 'Erro interno ao atualizar reserva.' });
  }
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await query('DELETE FROM reservas WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Reserva não encontrada.' });
    }

    return res.status(200).json({ message: 'Reserva removida com sucesso.' });
  } catch (error) {
    console.error('Erro ao remover reserva:', error.message);
    return res.status(500).json({ error: 'Erro interno ao remover reserva.' });
  }
});

module.exports = router;
