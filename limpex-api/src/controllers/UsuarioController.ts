import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { UserRepository } from '../repositories/UserRepository';

export class UsuarioController {
  static async getProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ error: 'Usuário não autenticado.' });
        return;
      }

      const profile = await UserRepository.findProfileById(req.userId);
      if (!profile) {
        res.status(404).json({ error: 'Perfil não encontrado.' });
        return;
      }

      res.status(200).json(profile);
    } catch (error) {
      console.error('Erro ao buscar perfil:', error);
      res.status(500).json({ error: 'Erro interno ao buscar perfil.' });
    }
  }

  static async updateProfile(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        res.status(401).json({ error: 'Usuário não autenticado.' });
        return;
      }

      const { nome, telefone, foto_perfil } = req.body;
      if (typeof nome !== 'string' || !nome.trim()) {
        res.status(400).json({ error: 'Informe um nome válido.' });
        return;
      }
      if (typeof telefone !== 'string') {
        res.status(400).json({ error: 'Informe um telefone válido.' });
        return;
      }
      if (
        foto_perfil !== null &&
        typeof foto_perfil !== 'string'
      ) {
        res.status(400).json({ error: 'Informe uma foto de perfil válida.' });
        return;
      }

      const profile = await UserRepository.updateProfile(req.userId, {
        nome: nome.trim(),
        telefone: telefone.trim() || null,
        foto_perfil:
          typeof foto_perfil === 'string' ? foto_perfil.trim() || null : null,
      });
      if (!profile) {
        res.status(404).json({ error: 'Perfil não encontrado.' });
        return;
      }

      res.status(200).json(profile);
    } catch (error) {
      console.error('Erro ao atualizar perfil:', error);
      res.status(500).json({ error: 'Erro interno ao atualizar perfil.' });
    }
  }
}
