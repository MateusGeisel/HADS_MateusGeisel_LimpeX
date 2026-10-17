import { Request, Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { PrestadorRepository } from '../repositories/PrestadorRepository';
import { ServicoRepository } from '../repositories/ServicoRepository';

export class PrestadorController {
  // --- Métodos Existentes ---
  static async consultarCnpj(req: AuthenticatedRequest, res: Response) {
    // Mantém a tua implementação do consultarCnpj aqui
  }

  static async salvarDadosFiscais(req: AuthenticatedRequest, res: Response) {
    // Mantém a tua implementação do salvarDadosFiscais aqui
  }

  static async registrarProgressoTrilha(req: AuthenticatedRequest, res: Response) {
    // Mantém a tua implementação do registrarProgressoTrilha aqui
  }

  // --- Novos Métodos para a Vitrine de Serviços ---

  // Listar todos os prestadores (Vitrine para Contratantes)
  static async listarTodos(req: Request, res: Response): Promise<void> {
    try {
      const prestadores = await PrestadorRepository.listarTodos();
      res.status(200).json(prestadores);
    } catch (error) {
      console.error('Erro ao listar prestadores:', error);
      res.status(500).json({ error: 'Erro interno ao buscar prestadores.' });
    }
  }
  // Listar serviços de um prestador específico (para o próprio prestador)
  static async listarMeusServicos(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const id_usuario = req.userId;
    if (!id_usuario) {
      res.status(401).json({ error: 'Usuário não autenticado.' });
      return;
    }

    const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
    if (!prestador) {
      res.status(403).json({ error: 'Apenas prestadores podem acessar seus serviços.' });
      return;
    }

    const servicos = await ServicoRepository.listarPorPrestador(prestador.id_prestador);
    res.status(200).json(servicos);
  } catch (error) {
    console.error('Erro ao listar meus serviços:', error);
    res.status(500).json({ error: 'Erro interno ao buscar serviços.' });
  }
}

static async atualizarAgenda(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const id_usuario = req.userId;
    const { agenda_disponivel } = req.body;

    if (!id_usuario) {
      res.status(401).json({ error: 'Usuário não autenticado.' });
      return;
    }

    const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
    if (!prestador) {
      res.status(403).json({ error: 'Prestador não encontrado.' });
      return;
    }

    await PrestadorRepository.atualizarAgendaDisponivel(prestador.id_prestador, agenda_disponivel);
    res.status(200).json({ message: 'Status da agenda atualizado com sucesso!' });
  } catch (error) {
    console.error('Erro ao atualizar agenda:', error);
    res.status(500).json({ error: 'Erro interno ao atualizar agenda.' });
  }
}
  // Buscar perfil público do prestador com seus serviços
  static async buscarPerfil(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const idPrestador = Number(id);

      const prestador = await PrestadorRepository.buscarPorId(idPrestador);
      if (!prestador) {
        res.status(404).json({ error: 'Prestador não encontrado.' });
        return;
      }

      const servicos = await ServicoRepository.listarPorPrestador(idPrestador);

      res.status(200).json({
        ...prestador,
        servicos,
      });
    } catch (error) {
      console.error('Erro ao buscar perfil do prestador:', error);
      res.status(500).json({ error: 'Erro interno ao buscar perfil.' });
    }
  }

  // Prestador cadastra um novo serviço
  static async criarServico(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id_usuario = req.userId;
      if (!id_usuario) {
        res.status(401).json({ error: 'Usuário não autenticado.' });
        return;
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        res.status(403).json({ error: 'Apenas prestadores cadastrados podem criar serviços.' });
        return;
      }

      const { id_categoria, nome, descricao, valor, modalidade } = req.body;

      if (!id_categoria || !nome || !valor) {
        res.status(400).json({ error: 'Categoria, nome e valor são obrigatórios.' });
        return;
      }

      const novoServico = await ServicoRepository.criar({
        id_prestador: prestador.id_prestador,
        id_categoria: Number(id_categoria),
        nome,
        descricao,
        valor: Number(valor),
        modalidade,
      });

      res.status(201).json({
        message: 'Serviço cadastrado com sucesso!',
        servico: novoServico,
      });
    } catch (error) {
      console.error('Erro ao criar serviço:', error);
      res.status(500).json({ error: 'Erro interno ao criar serviço.' });
    }
  }
}