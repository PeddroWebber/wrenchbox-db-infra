#!/usr/bin/env bash
set -euo pipefail

: "${PGHOST:?}"
: "${PGPASSWORD:?}"
: "${APP_PASSWORD:?}"
: "${AUTH_PASSWORD:?}"

psql "host=${PGHOST} port=5432 dbname=postgres user=wrenchboxadmin sslmode=require" \
  -v ON_ERROR_STOP=1 \
  -v app_password="$APP_PASSWORD" \
  -v auth_password="$AUTH_PASSWORD" \
  -f sql/roles.sql

for db in wrenchbox_homolog wrenchbox_prod; do
  psql "host=${PGHOST} port=5432 dbname=${db} user=wrenchboxadmin sslmode=require" \
    -v ON_ERROR_STOP=1 <<'SQL' || true
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'customers'
  ) THEN
    EXECUTE 'GRANT SELECT ("Id", "Document", "Status", "DocumentType") ON customers TO wrenchbox_auth';
  END IF;
END
$$;
SQL
done
