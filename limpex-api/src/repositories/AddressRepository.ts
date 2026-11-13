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

  static async update(
    id_endereco: number,
    id_usuario: number,
    address: Omit<AddressDTO, 'id_endereco' | 'id_usuario'>,
  ): Promise<AddressDTO | undefined> {
    const query = `
      UPDATE endereco
      SET cep = $1, rua = $2, numero = $3, bairro = $4,
          cidade = $5, estado = $6, latitude = $7, longitude = $8
      WHERE id_endereco = $9 AND id_usuario = $10
      RETURNING *;
    `;
    const values = [
      address.cep,
      address.rua,
      address.numero,
      address.bairro,
      address.cidade,
      address.estado,
      address.latitude ?? null,
      address.longitude ?? null,
      id_endereco,
      id_usuario,
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }
}