const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Goal = require('../models/Goal');

// @route   GET api/goals
// @desc    Get all user's saving goals
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const goals = await Goal.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.json(goals);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al obtener las metas.' });
  }
});

// @route   POST api/goals
// @desc    Create a new saving goal
// @access  Private
router.post('/', auth, async (req, res) => {
  const { name, targetAmount, savedAmount, emoji } = req.body;

  try {
    if (!name || targetAmount === undefined || !emoji) {
      return res.status(400).json({ message: 'Por favor, rellene los campos requeridos.' });
    }

    const newGoal = new Goal({
      userId: req.user.id,
      name,
      targetAmount,
      savedAmount: savedAmount || 0,
      emoji
    });

    const goal = await newGoal.save();
    res.json(goal);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al crear la meta.' });
  }
});

// @route   PATCH api/goals/:id
// @desc    Update a saving goal (e.g. increase savedAmount)
// @access  Private
router.patch('/:id', auth, async (req, res) => {
  const { name, targetAmount, savedAmount, emoji } = req.body;

  try {
    let goal = await Goal.findById(req.params.id);

    if (!goal) {
      return res.status(404).json({ message: 'Meta no encontrada.' });
    }

    // Verificar que el usuario posee la meta
    if (goal.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'No autorizado para modificar esta meta.' });
    }

    // Construir campos a actualizar
    const goalFields = {};
    if (name) goalFields.name = name;
    if (targetAmount !== undefined) goalFields.targetAmount = targetAmount;
    if (savedAmount !== undefined) goalFields.savedAmount = savedAmount;
    if (emoji) goalFields.emoji = emoji;

    goal = await Goal.findByIdAndUpdate(
      req.params.id,
      { $set: goalFields },
      { new: true } // Devolver el documento actualizado
    );

    res.json(goal);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al actualizar la meta.' });
  }
});

// @route   DELETE api/goals/:id
// @desc    Delete a saving goal
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const goal = await Goal.findById(req.params.id);

    if (!goal) {
      return res.status(404).json({ message: 'Meta no encontrada.' });
    }

    // Verificar que el usuario posee la meta
    if (goal.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'No autorizado para eliminar esta meta.' });
    }

    await Goal.findByIdAndDelete(req.params.id);
    res.json({ message: 'Meta eliminada con éxito.' });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: 'Error del servidor al eliminar la meta.' });
  }
});

module.exports = router;
