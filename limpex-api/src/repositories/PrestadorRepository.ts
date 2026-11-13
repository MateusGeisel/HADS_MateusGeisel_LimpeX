import { pool } from '../config/database';

export class PrestadorRepository {
  // Listar prestadores para o catálogo do cliente
  static async listarTodos() {
    const query = `
      SELECT 
        p.id_prestador,
        p.agenda_disponivel,
        p.selo_formalizado,
        p.optante_mei,
        p.status_validacao,
        p.biografia,
        u.id_usuario,
        u.nome,
        u.foto_perfil,
        (
          SELECT s.fotos
          FROM servico s
          WHERE s.id_prestador = p.id_prestador
            AND s.ativo = TRUE
            AND s.fotos IS NOT NULL
            AND s.fotos::text NOT IN ('{}', '[]', '')
          ORDER BY s.id_servico DESC
          LIMIT 1
        ) AS fotos_servicos,
        u.telefone,
        COALESCE(endereco_atual.cidade, l.cidade) AS cidade,
        COALESCE(endereco_atual.bairro, l.bairro) AS bairro,
        COALESCE(AVG(a.nota), 0.0)::NUMERIC(2,1) as media_nota,
        COUNT(a.id_avaliacao) as total_avaliacoes
      FROM prestador p
      JOIN usuario u ON p.id_usuario = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN LATERAL (
        SELECT e.cidade, e.bairro
        FROM endereco e
        WHERE e.id_usuario = u.id_usuario
        ORDER BY e.id_endereco DESC
        LIMIT 1
      ) endereco_atual ON TRUE
      LEFT JOIN avaliacao a ON a.id_avaliado = u.id_usuario
      WHERE u.status_conta = 'ATIVO'
      GROUP BY
        p.id_prestador,
        u.id_usuario,
        l.cidade,
        l.bairro,
        endereco_atual.cidade,
        endereco_atual.bairro
      ORDER BY p.selo_formalizado DESC, media_nota DESC;
    `;
    const result = await pool.query(query);
    return result.rows;
  }

  static async listarServicosDisponiveis() {
    const query = `
      SELECT
        p.id_prestador,
        p.agenda_disponivel,
        p.selo_formalizado,
        p.optante_mei,
        p.status_validacao,
        p.biografia,
        u.id_usuario,
        u.nome,
        u.foto_perfil,
        s.id_servico,
        s.nome AS nome_servico,
        s.descricao AS descricao_servico,
        s.valor,
        s.tipo_cobranca,
        s.modalidade,
        s.fotos AS fotos_servicos,
        c.nome AS nome_categoria,
        u.telefone,
        COALESCE(endereco_atual.cidade, l.cidade) AS cidade,
        COALESCE(endereco_atual.bairro, l.bairro) AS bairro,
        COALESCE(a.media_nota, 0.0)::NUMERIC(2,1) AS media_nota,
        COALESCE(a.total_avaliacoes, 0)::INTEGER AS total_avaliacoes
      FROM servico s
      JOIN prestador p ON s.id_prestador = p.id_prestador
      JOIN usuario u ON p.id_usuario = u.id_usuario
      LEFT JOIN categoria_servico c ON s.id_categoria = c.id_categoria
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN LATERAL (
        SELECT e.cidade, e.bairro
        FROM endereco e
        WHERE e.id_usuario = u.id_usuario
        ORDER BY e.id_endereco DESC
        LIMIT 1
      ) endereco_atual ON TRUE
      LEFT JOIN (
        SELECT
          id_avaliado,
          AVG(nota) AS media_nota,
          COUNT(*) AS total_avaliacoes
        FROM avaliacao
        GROUP BY id_avaliado
      ) a ON a.id_avaliado = u.id_usuario
      WHERE s.ativo = TRUE
        AND u.status_conta = 'ATIVO'
      ORDER BY
        media_nota DESC,
        total_avaliacoes DESC,
        p.selo_formalizado DESC,
        s.id_servico DESC;
    `;
    const result = await pool.query(query);
    return result.rows;
  }

  // Buscar detalhes do perfil de um prestador pelo ID
  static async buscarPorId(id_prestador: number) {
    const query = `
      SELECT 
        p.id_prestador,
        p.agenda_disponivel,
        p.selo_formalizado,
        p.optante_mei,
        p.razao_social,
        p.biografia,
        p.status_validacao,
        u.id_usuario,
        u.nome,
        u.email,
        u.telefone,
        u.foto_perfil,
        COALESCE(endereco_atual.cidade, l.cidade) AS cidade,
        COALESCE(endereco_atual.bairro, l.bairro) AS bairro,
        COALESCE(AVG(a.nota), 0.0)::NUMERIC(2,1) as media_nota,
        COUNT(a.id_avaliacao) as total_avaliacoes
      FROM prestador p
      JOIN usuario u ON p.id_usuario = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN LATERAL (
        SELECT e.cidade, e.bairro
        FROM endereco e
        WHERE e.id_usuario = u.id_usuario
        ORDER BY e.id_endereco DESC
        LIMIT 1
      ) endereco_atual ON TRUE
      LEFT JOIN avaliacao a ON a.id_avaliado = u.id_usuario
      WHERE p.id_prestador = $1
      GROUP BY
        p.id_prestador,
        u.id_usuario,
        l.cidade,
        l.bairro,
        endereco_atual.cidade,
        endereco_atual.bairro;
    `;
    const result = await pool.query(query, [id_prestador]);
    return result.rows[0];
  }

  // Buscar ID do prestador a partir do ID do usuário autenticado
  static async buscarPorUsuario(id_usuario: number) {
    const query = `SELECT id_prestador, agenda_disponivel FROM prestador WHERE id_usuario = $1;`;
    const result = await pool.query(query, [id_usuario]);
    return result.rows[0];
  }

  static async buscarPerfilPorUsuario(id_usuario: number) {
    const prestador = await this.buscarPorUsuario(id_usuario);
    if (!prestador) return undefined;
    return this.buscarPorId(prestador.id_prestador);
  }

  static async atualizarPerfilPorUsuario(
    id_usuario: number,
    data: {
      nome: string;
      telefone: string | null;
      foto_perfil: string | null;
      biografia: string | null;
    },
  ) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const usuario = await client.query(
        `UPDATE usuario
         SET nome = $1, telefone = $2, foto_perfil = $3
         WHERE id_usuario = $4 AND status_conta = 'ATIVO'
         RETURNING id_usuario, nome, email, telefone, foto_perfil`,
        [data.nome, data.telefone, data.foto_perfil, id_usuario],
      );
      const prestador = await client.query(
        `UPDATE prestador
         SET biografia = $1
         WHERE id_usuario = $2
         RETURNING id_prestador, biografia`,
        [data.biografia, id_usuario],
      );

      if (usuario.rows.length === 0 || prestador.rows.length === 0) {
        await client.query('ROLLBACK');
        return undefined;
      }

      await client.query('COMMIT');
      return { ...usuario.rows[0], ...prestador.rows[0] };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
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