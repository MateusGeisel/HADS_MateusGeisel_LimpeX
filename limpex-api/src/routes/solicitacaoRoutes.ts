import { Router } from 'express';
import { SolicitacaoController } from '../controllers/SolicitacaoController';
import { authMiddleware } from '../middlewares/authMiddleware';

const solicitacaoRouter = Router();

solicitacaoRouter.post('/', authMiddleware, SolicitacaoController.criarSolicitacao);
solicitacaoRouter.get('/minhas', authMiddleware, SolicitacaoController.listarMinhasSolicitacoes);
solicitacaoRouter.get('/disponiveis', authMiddleware, SolicitacaoController.listarDisponiveis);
solicitacaoRouter.get('/agenda', authMiddleware, SolicitacaoController.listarAgendaPrestador);
solicitacaoRouter.patch('/:id/aceitar', authMiddleware, SolicitacaoController.aceitarSolicitacao);
solicitacaoRouter.patch('/:id/recusar', authMiddleware, SolicitacaoController.recusarSolicitacao);
solicitacaoRouter.patch('/:id/concluir', authMiddleware, SolicitacaoController.concluirSolicitacao);
solicitacaoRouter.post('/:id/avaliar', authMiddleware, SolicitacaoController.avaliarSolicitacao);

export default solicitacaoRouter;