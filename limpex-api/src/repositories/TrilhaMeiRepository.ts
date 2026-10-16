import { pool } from '../config/database';

export interface TrilhaMeiProgressoDTO {
  id_progresso?: number;
  id_prestador: number;
  etapa_concluida: string; // Ex: 'LEITURA_GUIA', 'SIMULACAO_CUSTO', 'REDIRECIONADO_PORTAL'
  data_interacao?: Date;
}

export class TrilhaMeiRepository {
  static async registrarInteracao(id_prestador: number, etapa: string): Promise<TrilhaMeiProgressoDTO> {
    const query = `
      INSERT INTO trilha_mei_progresso (id_prestador, etapa_concluida)
      VALUES ($1, $2)
      RETURNING *;
    `;
    const result = await pool.query(query, [id_prestador, etapa]);
    return result.rows[0];
  }
}