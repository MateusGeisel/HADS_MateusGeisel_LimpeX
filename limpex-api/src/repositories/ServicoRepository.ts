import { pool } from '../config/database';

export interface ServicoDTO {
  id_prestador: number;
  id_categoria: number;
  nome: string;
  descricao?: string;
  valor: number;
  modalidade?: string; // 'DOMICILIO', 'ESTABELECIMENTO', 'REMOTO'
}

export class ServicoRepository {
  // Cadastrar um novo serviço ofertado pelo prestador
  static async criar(dados: ServicoDTO) {
    const query = `
      INSERT INTO servico (id_prestador, id_categoria, nome, descricao, valor, modalidade, ativo)
      VALUES ($1, $2, $3, $4, $5, $6, TRUE)
      RETURNING *;
    `;
    const values = [
      dados.id_prestador,
      dados.id_categoria,
      dados.nome,
      dados.descricao || null,
      dados.valor,
      dados.modalidade || 'DOMICILIO',
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  // Listar todos os serviços de um prestador específico (para a vitrine/perfil)
  static async listarPorPrestador(id_prestador: number) {
    const query = `
      SELECT s.*, c.nome as nome_categoria
      FROM servico s
      JOIN categoria_servico c ON s.id_categoria = c.id_categoria
      WHERE s.id_prestador = $1 AND s.ativo = TRUE
      ORDER BY s.id_servico DESC;
    `;
    const result = await pool.query(query, [id_prestador]);
    return result.rows;
  }

  // Desativar / Excluir um serviço do prestador
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