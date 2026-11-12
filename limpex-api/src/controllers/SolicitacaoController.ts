import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { PrestadorRepository } from '../repositories/PrestadorRepository';
import { SolicitacaoRepository } from '../repositories/SolicitacaoRepository';

export class SolicitacaoController {
  static async criarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_contratante = req.userId;
      if (!id_contratante) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const { id_servico, data_agendamento, horario_agendamento, observacoes } = req.body;

      const partesData =
        typeof data_agendamento === 'string' && data_agendamento.match(/^(\d{4})-(\d{2})-(\d{2})$/);
      const dataValida = partesData
        ? (() => {
            const data = new Date(Date.UTC(
              Number(partesData[1]),
              Number(partesData[2]) - 1,
              Number(partesData[3]),
            ));
            return data.getUTCFullYear() === Number(partesData[1]) &&
              data.getUTCMonth() === Number(partesData[2]) - 1 &&
              data.getUTCDate() === Number(partesData[3]);
          })()
        : false;
      if (!dataValida) {
        return res.status(400).json({ error: 'Informe uma data válida para o agendamento.' });
      }
      if (typeof horario_agendamento !== 'string' ||
          !/^([01]\d|2[0-3]):[0-5]\d$/.test(horario_agendamento)) {
        return res.status(400).json({ error: 'Informe um horário válido para o agendamento.' });
      }

      const idServico = id_servico == null ? undefined : Number(id_servico);
      if (idServico !== undefined && (!Number.isInteger(idServico) || idServico <= 0)) {
        return res.status(400).json({ error: 'Serviço inválido.' });
      }

      const novaSolicitacao = await SolicitacaoRepository.criar({
        id_contratante,
        id_servico: idServico,
        data_agendamento,
        observacoes: [observacoes, `Horário solicitado: ${horario_agendamento}`]
          .filter((item) => typeof item === 'string' && item.trim())
          .join('\n'),
      });
      if (!novaSolicitacao) {
        return res.status(400).json({
          error: 'O serviço não está disponível ou a agenda do prestador está fechada.',
        });
      }

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
      const id_usuario = req.userId;
      if (!id_usuario) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }
      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        return res.status(403).json({ error: 'Apenas prestadores podem acessar solicitações.' });
      }
      if (!prestador.agenda_disponivel) {
        return res.status(200).json([]);
      }

      const solicitacoes = await SolicitacaoRepository.listarDisponiveis(prestador.id_prestador);
      return res.status(200).json(solicitacoes);
    } catch (error) {
      console.error('Erro ao listar solicitações disponíveis:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar oportunidades.' });
    }
  }

  static async listarAgendaPrestador(req: AuthenticatedRequest, res: Response) {
    try {
      const id_usuario = req.userId;
      if (!id_usuario) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        return res.status(403).json({ error: 'Apenas prestadores podem acessar a agenda.' });
      }

      const solicitacoes = await SolicitacaoRepository.listarAgendaPrestador(prestador.id_prestador);
      return res.status(200).json(solicitacoes);
    } catch (error) {
      console.error('Erro ao listar agenda do prestador:', error);
      return res.status(500).json({ error: 'Erro interno ao buscar a agenda.' });
    }
  }

  static async aceitarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_prestador = req.userId;
      const { id } = req.params;

      if (!id_prestador) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }
      const id_solicitacao = Number(id);
      if (!Number.isInteger(id_solicitacao) || id_solicitacao <= 0) {
        return res.status(400).json({ error: 'Solicitação inválida.' });
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_prestador);
      if (!prestador) {
        return res.status(403).json({ error: 'Apenas prestadores podem aceitar solicitações.' });
      }
      const solicitacaoAceita = await SolicitacaoRepository.aceitarSolicitacao(
        id_solicitacao,
        prestador.id_prestador,
      );

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

  static async recusarSolicitacao(req: AuthenticatedRequest, res: Response) {
    try {
      const id_usuario = req.userId;
      const id_solicitacao = Number(req.params.id);
      if (!id_usuario) {
        return res.status(401).json({ error: 'Usuário não autenticado.' });
      }
      if (!Number.isInteger(id_solicitacao) || id_solicitacao <= 0) {
        return res.status(400).json({ error: 'Solicitação inválida.' });
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        return res.status(403).json({ error: 'Apenas prestadores podem recusar solicitações.' });
      }

      const solicitacaoRecusada = await SolicitacaoRepository.recusarSolicitacao(
        id_solicitacao,
        prestador.id_prestador,
      );
      if (!solicitacaoRecusada) {
        return res.status(400).json({ error: 'Solicitação indisponível ou já respondida.' });
      }

      return res.status(200).json({
        message: 'Solicitação recusada.',
        solicitacao: solicitacaoRecusada,
      });
    } catch (error) {
      console.error('Erro ao recusar solicitação:', error);
      return res.status(500).json({ error: 'Erro interno ao recusar a solicitação.' });
    }
  }
}