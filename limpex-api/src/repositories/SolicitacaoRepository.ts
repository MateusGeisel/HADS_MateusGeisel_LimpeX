import { pool } from '../config/database';

export interface SolicitacaoDTO {
  id_solicitacao?: number;
  id_contratante: number;
  id_servico?: number;
  data_agendamento: string;
  observacoes?: string;
  status?: string;
}

export class SolicitacaoRepository {
  // Criar solicitação usando id_contratante e observacoes do banco
  static async criar(dados: SolicitacaoDTO) {
    const query = `
      INSERT INTO solicitacao 
        (id_contratante, id_servico, data_agendamento, observacoes, status)
      VALUES ($1, $2, $3, $4, 'PENDENTE')
      RETURNING *;
    `;
    const values = [
      dados.id_contratante,
      dados.id_servico || null,
      dados.data_agendamento,
      dados.observacoes || null,
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  // Listar solicitações criadas pelo contratante/cliente
  static async listarPorCliente(id_contratante: number) {
    const query = `
      SELECT 
        s.*, 
        u.nome as nome_cliente,
        l.cidade,
        l.bairro,
        cat.nome as nome_categoria
      FROM solicitacao s
      JOIN usuario u ON s.id_contratante = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN servico ser ON s.id_servico = ser.id_servico
      LEFT JOIN categoria_servico cat ON ser.id_categoria = cat.id_categoria
      WHERE s.id_contratante = $1
      ORDER BY s.id_solicitacao DESC;
    `;
    const result = await pool.query(query, [id_contratante]);
    return result.rows;
  }

  // Listar todas as solicitações com status 'PENDENTE' para o feed do prestador
  static async listarDisponiveis() {
    const query = `
      SELECT 
        s.id_solicitacao,
        s.status,
        s.data_agendamento,
        s.observacoes as descricao_detalhada,
        u.nome as nome_cliente,
        l.cidade,
        l.bairro,
        cat.nome as nome_categoria
      FROM solicitacao s
      JOIN usuario u ON s.id_contratante = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN servico ser ON s.id_servico = ser.id_servico
      LEFT JOIN categoria_servico cat ON ser.id_categoria = cat.id_categoria
      WHERE s.status = 'PENDENTE'
      ORDER BY s.id_solicitacao DESC;
    `;
    const result = await pool.query(query);
    return result.rows;
  }

  // Aceitar solicitação e vincular ao prestador
  static async aceitarSolicitacao(id_solicitacao: number, id_prestador: number) {
    const query = `
      UPDATE solicitacao
      SET id_prestador = $1, status = 'ACEITO'
      WHERE id_solicitacao = $2 AND status = 'PENDENTE'
      RETURNING *;
    `;
    const result = await pool.query(query, [id_prestador, id_solicitacao]);
    return result.rows[0];
  }
}