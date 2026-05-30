const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', require('./routes/auth'));
app.use('/api/goals', require('./routes/goals'));
app.use('/api/transactions', require('./routes/transactions'));

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB conectado');
    app.listen(process.env.PORT, () =>
      console.log(`🚀 Servidor corriendo en puerto ${process.env.PORT}`)
    );
  })
  .catch(err => console.error('❌ Error:', err));