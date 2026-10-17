import { pool } from '../config/database';

export class UserRepository {
  static async findByEmail(email: string) {
    const query = `
      SELECT u.*, p.nome as perfil_nome 
      FROM usuario u
      LEFT JOIN usuario_perfil up ON u.id_usuario = up.id_usuario
      LEFT JOIN perfil p ON up.id_perfil = p.id_perfil
      WHERE u.email = $1;
    `;
    const result = await pool.query(query, [email]);
    return result.rows[0];
  }

  static async create(data: {
    nome: string;
    email: string;
    senhaHash: string;
    telefone?: string;
    tipo_perfil: 'CONTRATANTE' | 'PRESTADOR';
  }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Cria o usuário central
      const userResult = await client.query(
        `INSERT INTO usuario (nome, email, senha, telefone) 
         VALUES ($1, $2, $3, $4) 
         RETURNING id_usuario, nome, email, telefone`,
        [data.nome, data.email, data.senhaHash, data.telefone || null]
      );

      const newUser = userResult.rows[0];

      // 2. Busca ou garante o ID do Perfil
      let perfilResult = await client.query(
        `SELECT id_perfil FROM perfil WHERE nome = $1`,
        [data.tipo_perfil]
      );

      if (perfilResult.rows.length === 0) {
        perfilResult = await client.query(
          `INSERT INTO perfil (nome) VALUES ($1) RETURNING id_perfil`,
          [data.tipo_perfil]
        );
      }

      const idPerfil = perfilResult.rows[0].id_perfil;

      // 3. Vincula Usuário ao Perfil
      await client.query(
        `INSERT INTO usuario_perfil (id_usuario, id_perfil) VALUES ($1, $2)`,
        [newUser.id_usuario, idPerfil]
      );

      // 4. Se for PRESTADOR, cria o registro inicial na tabela prestador
      if (data.tipo_perfil === 'PRESTADOR') {
        await client.query(
          `INSERT INTO prestador (id_usuario, documento_numero) VALUES ($1, $2)`,
          [newUser.id_usuario, `PENDENTE_${newUser.id_usuario}`]
        );
      }

      await client.query('COMMIT');
      return { ...newUser, tipo_perfil: data.tipo_perfil };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}