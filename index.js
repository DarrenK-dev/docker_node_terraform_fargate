const express = require('express');
const PORT = process.env.PORT | 3003;

const app = express();

app.get('/', (req, res) => {
  res.status(200);
  res.json({
    website: "darrenk.dev",
    tutorial: "simple-node-app-with-terraform-on-aws",
    tags: ["aws", "node", "docker", "terraform", "fargate"]
  });
  res.end()
})

app.listen(PORT, () => {
  console.log(`Node server is listening on port ${PORT}`)
})