import { pool } from '../config/database';

export interface AddressDTO {
  id_endereco?: number;
  id_usuario: number;
  cep: string;
  rua: string;
  numero: string;
  bairro: string;
  cidade: string;
  estado: string;
  latitude?: number;
  longitude?: number;
}

export class AddressRepository {
  static async create(address: AddressDTO): Promise<AddressDTO> {
    const query = `
      INSERT INTO endereco (id_usuario, cep, rua, numero, bairro, cidade, estado, latitude, longitude)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *;
    `;
    const values = [
      address.id_usuario,
      address.cep,
      address.rua,
      address.numero,
      address.bairro,
      address.cidade,
      address.estado,
      address.latitude || null,
      address.longitude || null,
    ];

    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async findByUserId(id_usuario: number): Promise<AddressDTO[]> {
    const query = `SELECT * FROM endereco WHERE id_usuario = $1 ORDER BY id_endereco DESC;`;
    const result = await pool.query(query, [id_usuario]);
    return result.rows;
  }
}