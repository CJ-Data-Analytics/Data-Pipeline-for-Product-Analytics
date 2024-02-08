// server.js
const express = require('express');
const bodyParser = require('body-parser');
const collectInappData = require('./app_activity');
const collectStripeData = require('./stripe');

const app = express();
app.use(bodyParser.json());

app.all('/app_activity', collectInappData);
app.all('/stripe', collectStripeData);

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
