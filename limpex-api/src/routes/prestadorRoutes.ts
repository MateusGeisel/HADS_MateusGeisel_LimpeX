import { Router } from 'express';
import { PrestadorController } from '../controllers/PrestadorController';
import { authMiddleware } from '../middlewares/authMiddleware';

const prestadorRouter = Router();

// Rota de consulta externa de CNPJ
prestadorRouter.get('/cnpj/:cnpj', authMiddleware, PrestadorController.consultarCnpj);

// Rota para salvar dados do prestador
prestadorRouter.post('/dados-fiscais', authMiddleware, PrestadorController.salvarDadosFiscais);

//Rota para registrar progresso da trilha MEI
prestadorRouter.post('/trilha-mei', authMiddleware, PrestadorController.registrarProgressoTrilha);

// Rota pública / autenticada para contratantes navegarem
prestadorRouter.get('/', authMiddleware, PrestadorController.listarTodos);
prestadorRouter.get('/:id', authMiddleware, PrestadorController.buscarPerfil);

// Rotas do prestador para gerenciar seus serviços
prestadorRouter.post('/servicos', authMiddleware, PrestadorController.criarServico);

// Rota para listar serviços do prestador autenticado
prestadorRouter.get('/servicos/meus', authMiddleware, PrestadorController.listarMeusServicos);
prestadorRouter.patch('/agenda', authMiddleware, PrestadorController.atualizarAgenda);

export default prestadorRouter;