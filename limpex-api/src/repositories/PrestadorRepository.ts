import { pool } from '../config/database';

export class PrestadorRepository {
  // Listar prestadores para o catálogo do cliente
  static async listarTodos() {
    const query = `
      SELECT 
        p.id_prestador,
        p.selo_formalizado,
        p.optante_mei,
        p.status_validacao,
        u.id_usuario,
        u.nome,
        u.foto_perfil,
        u.telefone,
        l.cidade,
        l.bairro,
        COALESCE(AVG(a.nota), 5.0)::NUMERIC(2,1) as media_nota,
        COUNT(a.id_avaliacao) as total_avaliacoes
      FROM prestador p
      JOIN usuario u ON p.id_usuario = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN avaliacao a ON a.id_avaliado = u.id_usuario
      WHERE u.status_conta = 'ATIVO'
      GROUP BY p.id_prestador, u.id_usuario, l.cidade, l.bairro
      ORDER BY p.selo_formalizado DESC, media_nota DESC;
    `;
    const result = await pool.query(query);
    return result.rows;
  }

  // Buscar detalhes do perfil de um prestador pelo ID
  static async buscarPorId(id_prestador: number) {
    const query = `
      SELECT 
        p.id_prestador,
        p.selo_formalizado,
        p.optante_mei,
        p.razao_social,
        p.status_validacao,
        u.id_usuario,
        u.nome,
        u.email,
        u.telefone,
        u.foto_perfil,
        l.cidade,
        l.bairro,
        COALESCE(AVG(a.nota), 5.0)::NUMERIC(2,1) as media_nota,
        COUNT(a.id_avaliacao) as total_avaliacoes
      FROM prestador p
      JOIN usuario u ON p.id_usuario = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN avaliacao a ON a.id_avaliado = u.id_usuario
      WHERE p.id_prestador = $1
      GROUP BY p.id_prestador, u.id_usuario, l.cidade, l.bairro;
    `;
    const result = await pool.query(query, [id_prestador]);
    return result.rows[0];
  }

  // Buscar ID do prestador a partir do ID do usuário autenticado
  static async buscarPorUsuario(id_usuario: number) {
    const query = `SELECT id_prestador FROM prestador WHERE id_usuario = $1;`;
    const result = await pool.query(query, [id_usuario]);
    return result.rows[0];
  }

  // Atualizar a disponibilidade da agenda do prestador
  static async atualizarAgendaDisponivel(id_prestador: number, agendaDisponivel: boolean) {
  const query = `
    UPDATE prestador
    SET agenda_disponivel = $1
    WHERE id_prestador = $2
    RETURNING *;
  `;
  const result = await pool.query(query, [agendaDisponivel, id_prestador]);
  return result.rows[0];
  }
}