import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';

const router = Router();

// Usando métodos estáticos diretamente, sem dar "new AuthController()"
router.post('/register', AuthController.register);
router.post('/login', AuthController.login);

export default router;