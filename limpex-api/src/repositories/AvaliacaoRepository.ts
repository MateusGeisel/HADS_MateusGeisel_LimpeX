import { pool } from '../config/database';

type ResultadoAvaliacao =
  | { resultado: 'NAO_ENCONTRADA' }
  | { resultado: 'NAO_E_CONTRATANTE' }
  | { resultado: 'NAO_CONCLUIDA' }
  | { resultado: 'JA_AVALIADA' }
  | { resultado: 'PRESTADOR_NAO_ENCONTRADO' }
  | { resultado: 'CRIADA'; avaliacao: Record<string, unknown> };

export class AvaliacaoRepository {
  static async criar(
    id_solicitacao: number,
    id_avaliador: number,
    nota: number,
    comentario: string | null,
  ): Promise<ResultadoAvaliacao> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const solicitacao = await client.query(
        `SELECT s.id_contratante, s.status, p.id_usuario AS id_avaliado
         FROM solicitacao s
         LEFT JOIN prestador p ON p.id_prestador = s.id_prestador
         WHERE s.id_solicitacao = $1
         FOR UPDATE OF s;`,
        [id_solicitacao],
      );
      const dadosSolicitacao = solicitacao.rows[0];
      if (!dadosSolicitacao) {
        await client.query('ROLLBACK');
        return { resultado: 'NAO_ENCONTRADA' };
      }
      if (dadosSolicitacao.id_contratante !== id_avaliador) {
        await client.query('ROLLBACK');
        return { resultado: 'NAO_E_CONTRATANTE' };
      }
      if (dadosSolicitacao.status !== 'CONCLUIDO') {
        await client.query('ROLLBACK');
        return { resultado: 'NAO_CONCLUIDA' };
      }
      if (dadosSolicitacao.id_avaliado == null) {
        await client.query('ROLLBACK');
        return { resultado: 'PRESTADOR_NAO_ENCONTRADO' };
      }

      const avaliacaoExistente = await client.query(
        `SELECT 1
         FROM avaliacao
         WHERE id_solicitacao = $1 AND id_avaliador = $2
         LIMIT 1;`,
        [id_solicitacao, id_avaliador],
      );
      if (avaliacaoExistente.rows[0]) {
        await client.query('ROLLBACK');
        return { resultado: 'JA_AVALIADA' };
      }

      const inserida = await client.query(
        `INSERT INTO avaliacao
          (id_solicitacao, id_avaliador, id_avaliado, nota, comentario)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id_avaliacao, id_solicitacao, id_avaliador, id_avaliado,
                   nota, comentario, criado_em;`,
        [
          id_solicitacao,
          id_avaliador,
          dadosSolicitacao.id_avaliado,
          nota,
          comentario,
        ],
      );
      await client.query('COMMIT');
      return { resultado: 'CRIADA', avaliacao: inserida.rows[0] };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async listarPorPrestador(id_prestador: number) {
    const result = await pool.query(
      `SELECT
         a.id_avaliacao,
         a.id_solicitacao,
         a.nota,
         a.comentario,
         a.criado_em,
         u.nome AS nome_avaliador
       FROM avaliacao a
       JOIN prestador p ON p.id_usuario = a.id_avaliado
       LEFT JOIN usuario u ON u.id_usuario = a.id_avaliador
       WHERE p.id_prestador = $1
       ORDER BY a.criado_em DESC, a.id_avaliacao DESC;`,
      [id_prestador],
    );
    return result.rows;
  }
}
