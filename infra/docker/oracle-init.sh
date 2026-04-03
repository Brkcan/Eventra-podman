#!/bin/sh
set -eu

CONNECT_STRING="${ORACLE_APP_USER}/${ORACLE_APP_PASSWORD}@//${ORACLE_CONNECT_STRING}"

echo "[oracle-init] waiting for Oracle app user schema"
until printf 'select 1 from dual;\nexit\n' | sqlplus -s "${CONNECT_STRING}" >/dev/null 2>&1; do
  sleep 5
done

TABLE_EXISTS="$(
  printf "set heading off feedback off pagesize 0 verify off echo off\nselect count(*) from user_tables where table_name = 'EVENTS';\nexit\n" \
    | sqlplus -s "${CONNECT_STRING}" \
    | tr -d '[:space:]'
)"

if [ "${TABLE_EXISTS}" = "1" ]; then
  echo "[oracle-init] schema already present, skipping"
  exit 0
fi

echo "[oracle-init] applying oracle schema"
sqlplus -s "${CONNECT_STRING}" @/work/infra/unix/oracle-schema.sql
echo "[oracle-init] schema applied"
