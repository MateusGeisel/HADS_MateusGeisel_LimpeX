import { Router } from 'express';
import { PrestadorController } from '../controllers/PrestadorController';
import { authMiddleware } from '../middlewares/authMiddleware';

const prestadorRouter = Router();

// 1. Rotas estáticas / específicas do prestador (Fiscais e MEI) - PROTEGIDAS
prestadorRouter.get('/cnpj/:cnpj', authMiddleware, PrestadorController.consultarCnpj);
prestadorRouter.post('/dados-fiscais', authMiddleware, PrestadorController.salvarDadosFiscais);
prestadorRouter.post('/trilha-mei', authMiddleware, PrestadorController.registrarProgressoTrilha);

// 2. Rotas de gestão de serviços e agenda - PROTEGIDAS
prestadorRouter.get('/servicos/meus', authMiddleware, PrestadorController.listarMeusServicos);
prestadorRouter.post('/servicos', authMiddleware, PrestadorController.criarServico);
prestadorRouter.put('/servicos/:id', authMiddleware, PrestadorController.atualizarServico);
prestadorRouter.delete('/servicos/:id', authMiddleware, PrestadorController.excluirServico);
prestadorRouter.patch('/agenda', authMiddleware, PrestadorController.atualizarAgenda);

// 3. Rotas da Vitrine (🟢 PÚBLICAS)
// Removido o authMiddleware da listagem geral
prestadorRouter.get('/', PrestadorController.listarTodos);

// 4. Rotas dinâmicas por ID (🟢 PÚBLICAS para a Vitrine)
// Removido o authMiddleware do perfil público
prestadorRouter.get('/:id', PrestadorController.buscarPerfil);

export default prestadorRouter;