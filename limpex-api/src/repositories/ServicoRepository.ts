import { pool } from '../config/database';

export interface ServicoDTO {
  id_prestador: number;
  id_categoria: number;
  nome: string;
  descricao?: string;
  valor: number;
  tipo_cobranca?: 'HORA' | 'TURNO' | 'FIXO';
  fotos?: string[];
  modalidade?: string;
}

export class ServicoRepository {
  static async criar(dados: ServicoDTO) {
    const query = `
      INSERT INTO servico (id_prestador, id_categoria, nome, descricao, valor, tipo_cobranca, fotos, modalidade, ativo)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, TRUE)
      RETURNING *;
    `;
    const values = [
      dados.id_prestador,
      dados.id_categoria,
      dados.nome,
      dados.descricao || null,
      dados.valor,
      dados.tipo_cobranca || 'HORA',
      dados.fotos || [],
      dados.modalidade || 'DOMICILIO',
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async listarPorPrestador(id_prestador: number) {
    const query = `
      SELECT s.*, c.nome as nome_categoria
      FROM servico s
      LEFT JOIN categoria_servico c ON s.id_categoria = c.id_categoria
      WHERE s.id_prestador = $1 AND s.ativo = TRUE
      ORDER BY s.id_servico DESC;
    `;
    const result = await pool.query(query, [id_prestador]);
    return result.rows;
  }

  static async desativar(id_servico: number, id_prestador: number) {
    const query = `
      UPDATE servico
      SET ativo = FALSE
      WHERE id_servico = $1 AND id_prestador = $2
      RETURNING *;
    `;
    const result = await pool.query(query, [id_servico, id_prestador]);
    return result.rows[0];
  }
}