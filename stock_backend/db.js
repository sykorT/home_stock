const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.SUPABASE_DB_URL,
    ssl: { rejectUnauthorized: false } // Supabase vyžaduje SSL
});

module.exports = pool;
