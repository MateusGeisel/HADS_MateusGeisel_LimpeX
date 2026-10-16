import { Router } from 'express';
import { SolicitacaoController } from '../controllers/SolicitacaoController';
import { authMiddleware } from '../middlewares/authMiddleware';

const solicitacaoRouter = Router();

solicitacaoRouter.post('/', authMiddleware, SolicitacaoController.criarSolicitacao);
solicitacaoRouter.get('/minhas', authMiddleware, SolicitacaoController.listarMinhasSolicitacoes);

export default solicitacaoRouter;