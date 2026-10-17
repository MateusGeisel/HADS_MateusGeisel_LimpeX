import { Router } from 'express';
import { SolicitacaoController } from '../controllers/SolicitacaoController';
import { authMiddleware } from '../middlewares/authMiddleware';

const solicitacaoRouter = Router();

solicitacaoRouter.post('/', authMiddleware, SolicitacaoController.criarSolicitacao);
solicitacaoRouter.get('/minhas', authMiddleware, SolicitacaoController.listarMinhasSolicitacoes);
solicitacaoRouter.get('/disponiveis', authMiddleware, SolicitacaoController.listarDisponiveis);
solicitacaoRouter.patch('/:id/aceitar', authMiddleware, SolicitacaoController.aceitarSolicitacao);

export default solicitacaoRouter;