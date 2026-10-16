import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { pool } from './config/database';
import authRoutes from './routes/authRoutes';
import addressRouter from './routes/addressRoutes';
import prestadorRouter from './routes/prestadorRoutes';
import solicitacaoRouter from './routes/solicitacaoRoutes';

dotenv.config();

const app = express();

// Configuração liberada de CORS para testes locais com Flutter Web / Mobile
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

app.use(express.json());

// Rotas da API
app.use('/auth', authRoutes);
app.use('/address', addressRouter);
app.use('/prestador', prestadorRouter);
app.use('/solicitacoes', solicitacaoRouter);

// Rota de Teste (Healthcheck)
app.get('/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ status: 'API Limpex Rodando!', db_time: result.rows[0].now });
  } catch (error) {
    res.status(500).json({ error: 'Erro ao conectar no banco de dados' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor Limpex rodando na porta ${PORT}`);
});