import { pool } from '../config/database';

export interface SolicitacaoDTO {
  id_solicitacao?: number;
  id_contratante: number;
  id_servico?: number;
  data_agendamento: string;
  observacoes?: string;
  status?: string;
}

export class SolicitacaoRepository {
  private static incluirHorario(rows: Array<Record<string, unknown>>) {
    return rows.map((row) => {
      const notas = row.observacoes ?? row.descricao_detalhada;
      const observacoes = typeof notas === 'string' ? notas : '';
      const horario = observacoes.match(/Horário (?:solicitado|preferido):\s*(\d{2}:\d{2})/i);
      return { ...row, horario_agendamento: horario?.[1] ?? null };
    });
  }

  static async criar(dados: SolicitacaoDTO) {
    let idPrestador: number | null = null;
    if (dados.id_servico !== undefined) {
      const servico = await pool.query(
        `SELECT ser.id_prestador
         FROM servico ser
         JOIN prestador p ON p.id_prestador = ser.id_prestador
         WHERE ser.id_servico = $1 AND ser.ativo = TRUE AND p.agenda_disponivel = TRUE;`,
        [dados.id_servico],
      );
      if (!servico.rows[0]) return null;
      idPrestador = servico.rows[0].id_prestador;
    }

    const query = `
      INSERT INTO solicitacao
        (id_contratante, id_prestador, id_servico, data_agendamento, observacoes, status)
      VALUES ($1, $2, $3, $4, $5, 'PENDENTE')
      RETURNING *;
    `;
    const values = [
      dados.id_contratante,
      idPrestador,
      dados.id_servico ?? null,
      dados.data_agendamento,
      dados.observacoes ?? null,
    ];
    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async listarPorCliente(id_contratante: number) {
    const query = `
      SELECT
        s.*,
        u.nome AS nome_cliente,
        up.nome AS nome_prestador,
        ser.nome AS nome_servico,
        l.cidade,
        l.bairro,
        cat.nome AS nome_categoria
      FROM solicitacao s
      JOIN usuario u ON s.id_contratante = u.id_usuario
      LEFT JOIN prestador p ON s.id_prestador = p.id_prestador
      LEFT JOIN usuario up ON p.id_usuario = up.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN servico ser ON s.id_servico = ser.id_servico
      LEFT JOIN categoria_servico cat ON ser.id_categoria = cat.id_categoria
      WHERE s.id_contratante = $1
      ORDER BY s.id_solicitacao DESC;
    `;
    const result = await pool.query(query, [id_contratante]);
    return this.incluirHorario(result.rows);
  }

  static async listarDisponiveis(id_prestador: number) {
    const query = `
      SELECT
        s.id_solicitacao,
        s.id_servico,
        s.id_prestador,
        s.status,
        s.data_agendamento,
        s.observacoes AS descricao_detalhada,
        u.nome AS nome_cliente,
        ser.nome AS nome_servico,
        l.cidade,
        l.bairro,
        cat.nome AS nome_categoria
      FROM solicitacao s
      JOIN usuario u ON s.id_contratante = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN servico ser ON s.id_servico = ser.id_servico
      LEFT JOIN categoria_servico cat ON ser.id_categoria = cat.id_categoria
      WHERE s.status = 'PENDENTE'
        AND (s.id_prestador IS NULL OR s.id_prestador = $1)
      ORDER BY
        s.data_agendamento ASC,
        substring(
          COALESCE(s.observacoes, '')
          FROM 'Horário [^:]+: ([0-9]{2}:[0-9]{2})'
        ) ASC NULLS LAST,
        s.id_solicitacao DESC;
    `;
    const result = await pool.query(query, [id_prestador]);
    return this.incluirHorario(result.rows);
  }

  static async listarAgendaPrestador(id_prestador: number) {
    const query = `
      SELECT
        s.id_solicitacao,
        s.id_servico,
        s.id_prestador,
        s.status,
        s.data_agendamento,
        s.observacoes AS descricao_detalhada,
        u.nome AS nome_cliente,
        ser.nome AS nome_servico,
        l.cidade,
        l.bairro,
        cat.nome AS nome_categoria
      FROM solicitacao s
      JOIN usuario u ON s.id_contratante = u.id_usuario
      LEFT JOIN localizacao l ON u.id_localizacao = l.id_localizacao
      LEFT JOIN servico ser ON s.id_servico = ser.id_servico
      LEFT JOIN categoria_servico cat ON ser.id_categoria = cat.id_categoria
      WHERE (s.status = 'PENDENTE' AND (s.id_prestador IS NULL OR s.id_prestador = $1))
         OR (s.id_prestador = $1 AND s.status IN ('ACEITO', 'EM_ANDAMENTO'))
      ORDER BY
        s.data_agendamento ASC,
        substring(
          COALESCE(s.observacoes, '')
          FROM 'Horário [^:]+: ([0-9]{2}:[0-9]{2})'
        ) ASC NULLS LAST,
        s.id_solicitacao DESC;
    `;
    const result = await pool.query(query, [id_prestador]);
    return this.incluirHorario(result.rows);
  }

  static async aceitarSolicitacao(id_solicitacao: number, id_prestador: number) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const pendente = await client.query(
        `SELECT
           to_char(data_agendamento, 'YYYY-MM-DD') AS data_agendamento,
           observacoes
         FROM solicitacao
         WHERE id_solicitacao = $1
           AND status = 'PENDENTE'
           AND (id_prestador IS NULL OR id_prestador = $2)
         FOR UPDATE;`,
        [id_solicitacao, id_prestador],
      );
      if (!pendente.rows[0]) {
        await client.query('ROLLBACK');
        return undefined;
      }

      const observacoes =
        typeof pendente.rows[0].observacoes === 'string'
          ? pendente.rows[0].observacoes
          : '';
      const horario = observacoes.match(
        /Horário (?:solicitado|preferido):\s*(\d{2}:\d{2})/i,
      )?.[1];
      if (horario) {
        const data = String(pendente.rows[0].data_agendamento);
        if (!/^\d{4}-\d{2}-\d{2}$/.test(data)) {
          throw new Error('Data do agendamento inválida no banco de dados.');
        }
        await client.query(
          'SELECT pg_advisory_xact_lock($1::integer, hashtext($2));',
          [id_prestador, `${data} ${horario}`],
        );
        const conflito = await client.query(
          `SELECT 1
           FROM solicitacao
           WHERE id_prestador = $1
             AND id_solicitacao <> $2
             AND status IN ('ACEITO', 'EM_ANDAMENTO')
             AND data_agendamento::date = $3::date
             AND substring(
               COALESCE(observacoes, '')
               FROM 'Horário [^:]+: ([0-9]{2}:[0-9]{2})'
             ) = $4
           LIMIT 1;`,
          [id_prestador, id_solicitacao, data, horario],
        );
        if (conflito.rows[0]) {
          await client.query('ROLLBACK');
          return undefined;
        }
      }

      const result = await client.query(
        `UPDATE solicitacao
         SET id_prestador = COALESCE(id_prestador, $1), status = 'ACEITO'
         WHERE id_solicitacao = $2
           AND status = 'PENDENTE'
           AND (id_prestador IS NULL OR id_prestador = $1)
         RETURNING *;`,
        [id_prestador, id_solicitacao],
      );
      await client.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async recusarSolicitacao(id_solicitacao: number, id_prestador: number) {
    const query = `
      UPDATE solicitacao
      SET id_prestador = COALESCE(id_prestador, $1), status = 'RECUSADO'
      WHERE id_solicitacao = $2
        AND status = 'PENDENTE'
        AND (id_prestador IS NULL OR id_prestador = $1)
      RETURNING *;
    `;
    const result = await pool.query(query, [id_prestador, id_solicitacao]);
    return result.rows[0];
  }
}
