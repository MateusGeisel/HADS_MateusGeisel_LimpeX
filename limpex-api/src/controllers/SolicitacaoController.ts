import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { SolicitacaoRepository } from '../repositories/SolicitacaoRepository';

export class SolicitacaoController {
  static async criarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_cliente = req.userId;
      if (!id_cliente) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const { id_endereco, id_categoria, descricao_detalhada, data_agendamento, horario_agendamento } = req.body;

      if (!id_endereco || !id_categoria || !descricao_detalhada || !data_agendamento || !horario_agendamento) {
        return res.status(400).json({ error: 'Todos os campos obrigatórios devem ser preenchidos.' });
      }

      const novaSolicitacao = await SolicitacaoRepository.criar({
        id_cliente,
        id_endereco,
        id_categoria,
        descricao_detalhada,
        data_agendamento,
        horario_agendamento,
      });

      return res.status(201).json({
        message: 'Solicitação criada com sucesso!',
        solicitacao: novaSolicitacao,
      });
    } catch (error) {
      console.error('Erro ao criar solicitação:', error);
      return res.status(500).json({ error: 'Erro interno ao criar solicitação.' });
    }
  }

  static async listarMinhasSolicitacoes(req: AuthenticatedRequest, res: Response) {
    try {
      const id_cliente = req.userId;
      if (!id_cliente) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const solicitacoes = await SolicitacaoRepository.listarPorCliente(id_cliente);
      return res.status(200).json(solicitacoes);
    } catch (error) {
      console.error('Erro ao listar solicitações:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar solicitações.' });
    }
  }
}