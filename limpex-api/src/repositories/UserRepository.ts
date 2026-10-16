import { pool } from '../config/database';

export class UserRepository {
  async findByEmail(email: string) {
    const result = await pool.query('SELECT * FROM usuario WHERE email = $1', [email]);
    return result.rows[0];
  }

  async create(data: {
    nome: string;
    email: string;
    senhaHash: string;
    cpf?: string;
    telefone?: string;
    tipo_perfil: 'CLIENTE' | 'PRESTADOR' | 'AMBOS';
  }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Inserção na tabela de Usuário
      const userResult = await client.query(
        `INSERT INTO usuario (nome, email, senha, cpf, telefone, tipo_perfil) 
         VALUES ($1, $2, $3, $4, $5, $6) 
         RETURNING id_usuario, nome, email, tipo_perfil, telefone`,
        [
          data.nome,
          data.email,
          data.senhaHash,
          data.cpf || null,
          data.telefone || null,
          data.tipo_perfil,
        ]
      );

      const newUser = userResult.rows[0];

      // Se for PRESTADOR, cria o perfil básico de prestador
      if (data.tipo_perfil === 'PRESTADOR' || data.tipo_perfil === 'AMBOS') {
        await client.query(
          `INSERT INTO perfil_prestador (id_usuario) VALUES ($1)`,
          [newUser.id_usuario]
        );
      }

      await client.query('COMMIT');
      return newUser;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}