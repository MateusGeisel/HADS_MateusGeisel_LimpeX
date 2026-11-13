import { Router } from 'express';
import { AddressController } from '../controllers/AddressController';
import { authMiddleware } from '../middlewares/authMiddleware';

const addressRouter = Router();

addressRouter.post('/', authMiddleware, AddressController.createAddress);
addressRouter.get('/', authMiddleware, AddressController.getUserAddresses);
addressRouter.put('/:id', authMiddleware, AddressController.updateAddress);

export default addressRouter;