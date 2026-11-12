import { Request, Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { AvaliacaoRepository } from '../repositories/AvaliacaoRepository';
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
    if (typeof agenda_disponivel !== 'boolean') {
      res.status(400).json({ error: 'Informe se a agenda está disponível.' });
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

static async buscarStatusAgenda(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const id_usuario = req.userId;
    if (!id_usuario) {
      res.status(401).json({ error: 'Usuário não autenticado.' });
      return;
    }

    const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
    if (!prestador) {
      res.status(403).json({ error: 'Prestador não encontrado.' });
      return;
    }

    res.status(200).json({ agenda_disponivel: prestador.agenda_disponivel });
  } catch (error) {
    console.error('Erro ao buscar disponibilidade da agenda:', error);
    res.status(500).json({ error: 'Erro interno ao buscar a agenda.' });
  }
}

static async listarAvaliacoes(req: Request, res: Response): Promise<void> {
  try {
    const idPrestador = Number(req.params.id);
    if (!Number.isInteger(idPrestador) || idPrestador <= 0) {
      res.status(400).json({ error: 'ID de prestador inválido.' });
      return;
    }

    const prestador = await PrestadorRepository.buscarPorId(idPrestador);
    if (!prestador) {
      res.status(404).json({ error: 'Prestador não encontrado.' });
      return;
    }

    const avaliacoes = await AvaliacaoRepository.listarPorPrestador(idPrestador);
    res.status(200).json({
      media_nota: prestador.media_nota,
      total_avaliacoes: prestador.total_avaliacoes,
      avaliacoes,
    });
  } catch (error) {
    console.error('Erro ao listar avaliações do prestador:', error);
    res.status(500).json({ error: 'Erro interno ao buscar avaliações.' });
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

      const { id_categoria, nome, descricao, valor, tipo_cobranca, fotos, modalidade } = req.body;

      const categoriaId = Number(id_categoria);
      const valorServico = Number(valor);
      if (!Number.isInteger(categoriaId) || categoriaId <= 0 ||
          typeof nome !== 'string' || !nome.trim() ||
          !Number.isFinite(valorServico) || valorServico <= 0) {
        res.status(400).json({ error: 'Categoria, nome e valor são obrigatórios.' });
        return;
      }
      if (fotos !== undefined && (!Array.isArray(fotos) || !fotos.every((foto) => typeof foto === 'string'))) {
        res.status(400).json({ error: 'As fotos do serviço devem ser uma lista de URLs.' });
        return;
      }
      if (tipo_cobranca !== undefined && !['HORA', 'TURNO', 'FIXO'].includes(tipo_cobranca)) {
        res.status(400).json({ error: 'Tipo de cobrança inválido.' });
        return;
      }

      const novoServico = await ServicoRepository.criar({
        id_prestador: prestador.id_prestador,
        id_categoria: categoriaId,
        nome: nome.trim(),
        descricao,
        valor: valorServico,
        tipo_cobranca,
        fotos,
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

  static async atualizarServico(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id_usuario = req.userId;
      const id_servico = Number(req.params.id);
      if (!id_usuario) {
        res.status(401).json({ error: 'Usuário não autenticado.' });
        return;
      }
      if (!Number.isInteger(id_servico) || id_servico <= 0) {
        res.status(400).json({ error: 'ID de serviço inválido.' });
        return;
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        res.status(403).json({ error: 'Apenas prestadores cadastrados podem editar serviços.' });
        return;
      }

      const { id_categoria, nome, descricao, valor, tipo_cobranca, fotos } = req.body;
      const categoriaId = Number(id_categoria);
      const valorServico = Number(valor);
      if (!Number.isInteger(categoriaId) || categoriaId <= 0 ||
          typeof nome !== 'string' || !nome.trim() ||
          !Number.isFinite(valorServico) || valorServico <= 0) {
        res.status(400).json({ error: 'Categoria, nome e valor são obrigatórios.' });
        return;
      }
      if (fotos !== undefined && (!Array.isArray(fotos) || !fotos.every((foto) => typeof foto === 'string'))) {
        res.status(400).json({ error: 'As fotos do serviço devem ser uma lista de URLs.' });
        return;
      }
      if (tipo_cobranca !== undefined && !['HORA', 'TURNO', 'FIXO'].includes(tipo_cobranca)) {
        res.status(400).json({ error: 'Tipo de cobrança inválido.' });
        return;
      }

      const servico = await ServicoRepository.atualizar(id_servico, {
        id_prestador: prestador.id_prestador,
        id_categoria: categoriaId,
        nome: nome.trim(),
        descricao,
        valor: valorServico,
        tipo_cobranca,
        fotos,
      });
      if (!servico) {
        res.status(404).json({ error: 'Serviço não encontrado.' });
        return;
      }
      res.status(200).json({ message: 'Serviço atualizado com sucesso!', servico });
    } catch (error) {
      console.error('Erro ao atualizar serviço:', error);
      res.status(500).json({ error: 'Erro interno ao atualizar serviço.' });
    }
  }

  static async excluirServico(req: AuthenticatedRequest, res: Response): Promise<void> {
    try {
      const id_usuario = req.userId;
      const id_servico = Number(req.params.id);
      if (!id_usuario) {
        res.status(401).json({ error: 'Usuário não autenticado.' });
        return;
      }
      if (!Number.isInteger(id_servico) || id_servico <= 0) {
        res.status(400).json({ error: 'ID de serviço inválido.' });
        return;
      }

      const prestador = await PrestadorRepository.buscarPorUsuario(id_usuario);
      if (!prestador) {
        res.status(403).json({ error: 'Apenas prestadores cadastrados podem excluir serviços.' });
        return;
      }

      const servico = await ServicoRepository.desativar(id_servico, prestador.id_prestador);
      if (!servico) {
        res.status(404).json({ error: 'Serviço não encontrado.' });
        return;
      }
      res.status(200).json({ message: 'Serviço excluído com sucesso.' });
    } catch (error) {
      console.error('Erro ao excluir serviço:', error);
      res.status(500).json({ error: 'Erro interno ao excluir serviço.' });
    }
  }
}