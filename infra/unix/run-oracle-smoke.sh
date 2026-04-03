#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_SQL="$ROOT_DIR/infra/unix/oracle-schema.sql"
SMOKE_SQL="$ROOT_DIR/infra/unix/oracle-smoke-test.sql"

ORACLE_USER="${ORACLE_USER:-}"
ORACLE_PASSWORD="${ORACLE_PASSWORD:-}"
ORACLE_CONNECT_STRING="${ORACLE_CONNECT_STRING:-}"

if [[ -z "$ORACLE_USER" || -z "$ORACLE_PASSWORD" || -z "$ORACLE_CONNECT_STRING" ]]; then
  echo "ORACLE_USER, ORACLE_PASSWORD ve ORACLE_CONNECT_STRING env'leri gerekli." >&2
  exit 1
fi

if ! command -v sqlplus >/dev/null 2>&1; then
  echo "sqlplus bulunamadi. Oracle client/sqlplus kurulumu gerekli." >&2
  exit 1
fi

sqlplus -s "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_CONNECT_STRING}" @"$SCHEMA_SQL"
sqlplus -s "${ORACLE_USER}/${ORACLE_PASSWORD}@${ORACLE_CONNECT_STRING}" @"$SMOKE_SQL"
