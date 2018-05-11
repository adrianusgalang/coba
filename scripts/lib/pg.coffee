require('dotenv').config()

Pool = require('pg').Pool
module.exports = new Pool(
  host: process.env.PG_HOST
  database: process.env.PG_DATABASE
  user: process.env.PG_USERNAME
  password: process.env.PG_PASSWORD
)
