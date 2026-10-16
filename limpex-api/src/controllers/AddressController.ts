import { Response } from 'express';
import { AddressRepository } from '../repositories/AddressRepository';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';

export class AddressController {
  static async createAddress(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.userId;
      if (!userId) return res.status(401).json({ error: 'Usuário não autenticado.' });

      const { cep, rua, numero, bairro, cidade, estado, latitude, longitude } = req.body;

      if (!cep || !rua || !numero || !bairro || !cidade || !estado) {
        return res.status(400).json({ error: 'Preencha todos os campos obrigatórios do endereço.' });
      }

      const newAddress = await AddressRepository.create({
        id_usuario: userId,
        cep,
        rua,
        numero,
        bairro,
        cidade,
        estado,
        latitude,
        longitude,
      });

      return res.status(201).json({ message: 'Endereço cadastrado com sucesso!', address: newAddress });
    } catch (error) {
      console.error('Erro ao cadastrar endereço:', error);
      return res.status(500).json({ error: 'Erro interno ao salvar endereço.' });
    }
  }

  static async getUserAddresses(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.userId;
      if (!userId) return res.status(401).json({ error: 'Usuário não autenticado.' });

      const addresses = await AddressRepository.findByUserId(userId);
      return res.status(200).json(addresses);
    } catch (error) {
      console.error('Erro ao buscar endereços:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar endereços.' });
    }
  }
}