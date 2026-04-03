import oracledb from 'oracledb';

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.fetchAsString = [oracledb.CLOB];

function replaceDollarBinds(sqlText) {
  return sqlText.replace(/\$(\d+)/g, ':b$1');
}

function toOracleTimestamp(value) {
  if (value instanceof Date) {
    return value;
  }

  if (
    typeof value === 'string' &&
    /^\d{4}-\d{2}-\d{2}(?:[T ][0-9:.+-Z]+)?$/.test(value)
  ) {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  return value;
}

function normalizeBindValue(value) {
  if (value === undefined) {
    return null;
  }
  if (typeof value === 'boolean') {
    return value ? 1 : 0;
  }
  if (Array.isArray(value) || (value && typeof value === 'object' && !(value instanceof Date))) {
    return JSON.stringify(value);
  }
  return toOracleTimestamp(value);
}

function buildOracleBindParams(params = []) {
  const bindParams = {};
  params.forEach((value, index) => {
    bindParams[`b${index + 1}`] = normalizeBindValue(value);
  });
  return bindParams;
}

function buildReturningQuery(sqlText) {
  const match = sqlText.match(/\sreturning\s+([a-zA-Z0-9_]+)\s*$/i);
  if (!match) {
    return null;
  }

  const column = match[1];
  const sqlWithoutReturning = sqlText.replace(/\sreturning\s+[a-zA-Z0-9_]+\s*$/i, '');
  return {
    sql: `${sqlWithoutReturning} returning ${column} into :__eventra_returning__`,
    column
  };
}

function containsUnsupportedOraclePatterns(sqlText) {
  const mergeConflictPattern = new RegExp(['on', '\\s+', 'conflict'].join(''), 'i');
  const jsonObjectPattern = new RegExp(['json', 'b_build_object'].join(''), 'i');
  const intervalPattern = new RegExp(['make', '_interval'].join(''), 'i');
  const aggregateFilterPattern = new RegExp(['filter', '\\s*\\('].join(''), 'i');
  const castPattern = /::[a-z_]+/i;
  return (
    mergeConflictPattern.test(sqlText) ||
    jsonObjectPattern.test(sqlText) ||
    intervalPattern.test(sqlText) ||
    aggregateFilterPattern.test(sqlText) ||
    castPattern.test(sqlText)
  );
}

function normalizeOracleRows(rows) {
  if (!Array.isArray(rows)) {
    return [];
  }
  return rows.map((row) => {
    if (!row || typeof row !== 'object' || Array.isArray(row)) {
      return row;
    }
    return Object.fromEntries(
      Object.entries(row).map(([key, value]) => [String(key).toLowerCase(), value])
    );
  });
}

class OracleCompatClient {
  constructor(config) {
    this.config = config;
    this.connection = null;
    this.inTransaction = false;
  }

  async connect() {
    this.connection = await oracledb.getConnection({
      user: this.config.oracleUser,
      password: this.config.oraclePassword,
      connectString: this.config.oracleConnectString
    });
  }

  async query(sql, params = []) {
    if (!this.connection) {
      throw new Error('oracle connection not initialized');
    }

    const text = String(sql || '').trim();
    const lower = text.toLowerCase();

    if (lower === 'begin') {
      this.inTransaction = true;
      return { rows: [], rowCount: 0, rowsAffected: 0 };
    }
    if (lower === 'commit') {
      await this.connection.commit();
      this.inTransaction = false;
      return { rows: [], rowCount: 0, rowsAffected: 0 };
    }
    if (lower === 'rollback') {
      await this.connection.rollback();
      this.inTransaction = false;
      return { rows: [], rowCount: 0, rowsAffected: 0 };
    }

    if (containsUnsupportedOraclePatterns(text)) {
      throw new Error(
        `Oracle adapter cannot yet translate this SQL automatically: ${text.slice(0, 140)}`
      );
    }

    const returning = buildReturningQuery(text);
    const bindParams = buildOracleBindParams(Array.isArray(params) ? params : []);
    let statement = replaceDollarBinds(text);
    let executeBinds = bindParams;
    const options = { autoCommit: !this.inTransaction };

    if (returning) {
      statement = replaceDollarBinds(returning.sql);
      executeBinds = {
        ...bindParams,
        __eventra_returning__: { dir: oracledb.BIND_OUT, type: oracledb.STRING }
      };
    }

    const result = await this.connection.execute(statement, executeBinds, options);
    const rows = normalizeOracleRows(result.rows);

    if (returning) {
      const returnedValue = result.outBinds?.__eventra_returning__;
      return {
        rows: returnedValue ? [{ [returning.column]: returnedValue }] : [],
        rowCount: returnedValue ? 1 : 0,
        rowsAffected: result.rowsAffected || (returnedValue ? 1 : 0)
      };
    }

    return {
      rows,
      rowCount: rows.length || result.rowsAffected || 0,
      rowsAffected: result.rowsAffected || rows.length || 0
    };
  }

  async end() {
    if (this.connection) {
      await this.connection.close();
      this.connection = null;
    }
  }
}

export function createDatabaseClient(config) {
  return new OracleCompatClient(config);
}
