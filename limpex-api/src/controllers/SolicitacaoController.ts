import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { SolicitacaoRepository } from '../repositories/SolicitacaoRepository';

export class SolicitacaoController {
  static async criarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_contratante = req.userId;
      if (!id_contratante) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const { id_servico, data_agendamento, observacoes } = req.body;

      if (!data_agendamento) {
        return res.status(400).json({ error: 'A data do agendamento é obrigatória.' });
      }

      const novaSolicitacao = await SolicitacaoRepository.criar({
        id_contratante,
        id_servico,
        data_agendamento,
        observacoes,
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
      const id_contratante = req.userId;
      if (!id_contratante) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const solicitacoes = await SolicitacaoRepository.listarPorCliente(id_contratante);
      return res.status(200).json(solicitacoes);
    } catch (error) {
      console.error('Erro ao listar solicitações:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar solicitações.' });
    }
  }

  static async listarDisponiveis(req: AuthenticatedRequest, res: Response) {
    try {
      const solicitacoes = await SolicitacaoRepository.listarDisponiveis();
      return res.status(200).json(solicitacoes);
    } catch (error) {
      console.error('Erro ao listar solicitações disponíveis:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar oportunidades.' });
    }
  }

  static async aceitarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_prestador = req.userId;
      const { id } = req.params;

      if (!id_prestador) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const solicitacaoAceita = await SolicitacaoRepository.aceitarSolicitacao(Number(id), id_prestador);

      if (!solicitacaoAceita) {
        return res.status(400).json({ error: 'Solicitação indisponível ou já aceita.' });
      }

      return res.status(200).json({
        message: 'Serviço aceito com sucesso!',
        solicitacao: solicitacaoAceita,
      });
    } catch (error) {
      console.error('Erro ao aceitar solicitação:', error);
      return res.status(500).json({ error: 'Erro interno ao aceitar serviço.' });
    }
  }
}