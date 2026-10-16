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

export default prestadorRouter;