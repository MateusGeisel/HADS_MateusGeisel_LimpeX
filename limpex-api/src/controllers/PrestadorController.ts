import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { CnpjService } from '../services/CnpjService';
import { PrestadorRepository } from '../repositories/PrestadorRepository';
import { TrilhaMeiRepository } from '../repositories/TrilhaMeiRepository';

export class PrestadorController {
  // Rota pública/autenticada para consultar dados do CNPJ antes de salvar
  static async consultarCnpj(req: AuthenticatedRequest, res: Response) {
    try {
      const cnpj = req.params.cnpj as string;
      const dadosCnpj = await CnpjService.consultarCnpj(cnpj);

      if (!dadosCnpj) {
        return res.status(404).json({ error: 'CNPJ não encontrado ou inválido.' });
      }

      return res.status(200).json(dadosCnpj);
    } catch (error) {
      console.error('Erro no controller de CNPJ:', error);
      return res.status(500).json({ error: 'Erro interno ao consultar CNPJ.' });
    }
  }

  // Cadastrar ou atualizar dados fiscais do prestador
  static async salvarDadosFiscais(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.userId;
      if (!userId) return res.status(401).json({ error: 'Usuário não autenticado.' });

      const { tipo_documento, documento_numero, razao_social, inscricao_municipal, optante_mei } = req.body;

      if (!tipo_documento || !documento_numero) {
        return res.status(400).json({ error: 'Tipo de documento e número são obrigatórios.' });
      }

      const novoPrestador = await PrestadorRepository.create({
        id_usuario: userId,
        tipo_documento,
        documento_numero,
        razao_social,
        inscricao_municipal,
        optante_mei: optante_mei ?? (tipo_documento === 'CNPJ'),
        status_validacao: 'PENDENTE',
        selo_formalizado: tipo_documento === 'CNPJ',
      });

      return res.status(201).json({
        message: 'Dados fiscais cadastrados com sucesso!',
        prestador: novoPrestador,
      });
    } catch (error) {
      console.error('Erro ao salvar dados fiscais:', error);
      return res.status(500).json({ error: 'Erro interno ao salvar dados do prestador.' });
    }
  }
  //Trilha CNPJ classe PrestadorController:
static async registrarProgressoTrilha(req: AuthenticatedRequest, res: Response) {
  try {
    const userId = req.userId;
    if (!userId) return res.status(401).json({ error: 'Usuário não autenticado.' });

    const prestador = await PrestadorRepository.findByUsuarioId(userId);
    if (!prestador || !prestador.id_prestador) {
      return res.status(404).json({ error: 'Perfil de prestador não encontrado.' });
    }

    const { etapa_concluida } = req.body;
    if (!etapa_concluida) {
      return res.status(400).json({ error: 'Informe a etapa concluída.' });
    }

    const progresso = await TrilhaMeiRepository.registrarInteracao(prestador.id_prestador, etapa_concluida);

    return res.status(201).json({
      message: 'Progresso da trilha registrado!',
      progresso,
    });
  } catch (error) {
    console.error('Erro ao registrar trilha MEI:', error);
    return res.status(500).json({ error: 'Erro interno ao salvar progresso.' });
  }
}
}