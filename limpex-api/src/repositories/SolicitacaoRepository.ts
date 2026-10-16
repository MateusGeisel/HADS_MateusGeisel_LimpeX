import { pool } from '../config/database';

export interface SolicitacaoDTO {
  id_solicitacao?: number;
  id_cliente: number;
  id_endereco: number;
  id_categoria: number;
  descricao_detalhada: string;
  data_agendamento: string;
  horario_agendamento: string;
  status?: string; // 'ABERTO', 'ACEITO', 'CONCLUIDO', 'CANCELADO'
}

export class SolicitacaoRepository {
  static async criar(dados: SolicitacaoDTO) {
    const query = `
      INSERT INTO solicitacao 
        (id_cliente, id_endereco, id_categoria, descricao_detalhada, data_agendamento, horario_agendamento, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'ABERTO')
      RETURNING *;
    `;
    const values = [
      dados.id_cliente,
      dados.id_endereco,
      dados.id_categoria,
      dados.descricao_detalhada,
      dados.data_agendamento,
      dados.horario_agendamento,
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async listarPorCliente(id_cliente: number) {
    const query = `
      SELECT 
        s.*, 
        e.logradouro, e.numero, e.bairro, e.cidade,
        c.nome_categoria
      FROM solicitacao s
      JOIN endereco e ON s.id_endereco = e.id_endereco
      JOIN categoria_servico c ON s.id_categoria = c.id_categoria
      WHERE s.id_cliente = $1
      ORDER BY s.id_solicitacao DESC;
    `;
    const result = await pool.query(query, [id_cliente]);
    return result.rows;
  }
}