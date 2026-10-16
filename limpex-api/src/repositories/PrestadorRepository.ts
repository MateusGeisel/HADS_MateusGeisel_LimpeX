import { pool } from '../config/database';

export interface PrestadorDTO {
  id_prestador?: number;
  id_usuario: number;
  tipo_documento: 'CPF' | 'CNPJ';
  documento_numero: string;
  razao_social?: string;
  inscricao_municipal?: string;
  optante_mei?: boolean;
  status_validacao?: 'PENDENTE' | 'APROVADO' | 'RECUSADO';
  selo_formalizado?: boolean;
}

export class PrestadorRepository {
  static async create(prestador: PrestadorDTO): Promise<PrestadorDTO> {
    const query = `
      INSERT INTO prestador (
        id_usuario, tipo_documento, documento_numero, razao_social, 
        inscricao_municipal, optante_mei, status_validacao, selo_formalizado
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *;
    `;

    const values = [
      prestador.id_usuario,
      prestador.tipo_documento,
      prestador.documento_numero,
      prestador.razao_social || null,
      prestador.inscricao_municipal || null,
      prestador.optante_mei ?? false,
      prestador.status_validacao || 'PENDENTE',
      prestador.selo_formalizado ?? (prestador.tipo_documento === 'CNPJ'),
    ];

    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async findByUsuarioId(id_usuario: number): Promise<PrestadorDTO | null> {
    const query = `SELECT * FROM prestador WHERE id_usuario = $1;`;
    const result = await pool.query(query, [id_usuario]);
    return result.rows[0] || null;
  }
}