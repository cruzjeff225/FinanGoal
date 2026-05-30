const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Transaction = require('../models/Transaction');

// @route   GET api/transactions
// @desc    Get all user's transactions
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const transactions = await Transaction.find({ userId: req.user.id }).sort({ date: -1 });
    res.json(transactions);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al obtener las transacciones.' });
  }
});

// @route   POST api/transactions
// @desc    Create a new transaction
// @access  Private
router.post('/', auth, async (req, res) => {
  const { amount, description, category, isIncome, date } = req.body;

  try {
    if (amount === undefined || !description || !category || isIncome === undefined) {
      return res.status(400).json({ message: 'Por favor, rellene todos los campos requeridos.' });
    }

    const newTransaction = new Transaction({
      userId: req.user.id,
      amount,
      description,
      category,
      isIncome,
      date: date ? new Date(date) : Date.now()
    });

    const transaction = await newTransaction.save();
    res.json(transaction);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al registrar la transacción.' });
  }
});

// @route   DELETE api/transactions/:id
// @desc    Delete a transaction
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const transaction = await Transaction.findById(req.params.id);

    if (!transaction) {
      return res.status(404).json({ message: 'Transacción no encontrada.' });
    }

    // Verificar propiedad
    if (transaction.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'No autorizado para eliminar esta transacción.' });
    }

    await Transaction.findByIdAndDelete(req.params.id);
    res.json({ message: 'Transacción eliminada con éxito.' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al eliminar la transacción.' });
  }
});

module.exports = router;
