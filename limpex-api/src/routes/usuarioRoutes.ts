import { Router } from 'express';
import { UsuarioController } from '../controllers/UsuarioController';
import { authMiddleware } from '../middlewares/authMiddleware';

const usuarioRouter = Router();

usuarioRouter.get('/me', authMiddleware, UsuarioController.getProfile);
usuarioRouter.put('/me', authMiddleware, UsuarioController.updateProfile);

export default usuarioRouter;
