import { Router } from 'express';
import { PrestadorController } from '../controllers/PrestadorController';
import { authMiddleware } from '../middlewares/authMiddleware';

const prestadorRouter = Router();

// 1. Rotas estáticas / específicas do prestador (Fiscais e MEI)
prestadorRouter.get('/cnpj/:cnpj', authMiddleware, PrestadorController.consultarCnpj);
prestadorRouter.post('/dados-fiscais', authMiddleware, PrestadorController.salvarDadosFiscais);
prestadorRouter.post('/trilha-mei', authMiddleware, PrestadorController.registrarProgressoTrilha);

// 2. Rotas de gestão de serviços e agenda (Devem vir ANTES das rotas dinâmicas com /:id)
prestadorRouter.get('/servicos/meus', authMiddleware, PrestadorController.listarMeusServicos);
prestadorRouter.post('/servicos', authMiddleware, PrestadorController.criarServico);
prestadorRouter.patch('/agenda', authMiddleware, PrestadorController.atualizarAgenda);

// 3. Rotas da Vitrine (Públicas e Busca)
prestadorRouter.get('/', authMiddleware, PrestadorController.listarTodos);

// 4. ATENÇÃO: A rota com parâmetro de ID deve ficar SEMPRE ao final
prestadorRouter.get('/:id', authMiddleware, PrestadorController.buscarPerfil);

export default prestadorRouter;