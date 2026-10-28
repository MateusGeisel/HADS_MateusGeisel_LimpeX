import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

// Se houver DATABASE_URL (Supabase/Render), usa ela. Se não, usa as variáveis individuais.
export const pool = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: {
          rejectUnauthorized: false, // Necessário para a conexão com o Supabase
        },
      }
    : {
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT) || 5432,
        user: process.env.DB_USER || 'postgres',
        password: process.env.DB_PASSWORD || '12345678',
        database: process.env.DB_NAME || 'limpex_db',
        ssl: {
          rejectUnauthorized: false,
        },
      }
);