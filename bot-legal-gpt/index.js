const express = require('express');
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.post('/whatsapp', (req, res) => {
  console.log('Recibido:', req.body);
  res.set('Content-Type', 'text/xml');
  res.send(`
    <Response>
      <Message>Hola, esta es una prueba de conexión básica.</Message>
    </Response>
  `);
});

app.listen(3100, () => {
  console.log('Servidor corriendo en http://localhost:3100');
});
