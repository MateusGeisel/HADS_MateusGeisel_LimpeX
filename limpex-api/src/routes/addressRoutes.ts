import { Router } from 'express';
import { AddressController } from '../controllers/AddressController';
import { authMiddleware } from '../middlewares/authMiddleware';

const addressRouter = Router();

addressRouter.post('/', authMiddleware, AddressController.createAddress);
addressRouter.get('/', authMiddleware, AddressController.getUserAddresses);

export default addressRouter;