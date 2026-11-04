-- Papéis de menor privilégio. Senhas entram só por variável do psql, nunca neste arquivo.
-- psql -v app_password=... -v auth_password=... -f sql/roles.sql

SELECT format('CREATE ROLE wrenchbox_app LOGIN PASSWORD %L', :'app_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wrenchbox_app')
\gexec

SELECT format('CREATE ROLE wrenchbox_auth LOGIN PASSWORD %L', :'auth_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wrenchbox_auth')
\gexec

\connect wrenchbox_homolog
GRANT CONNECT ON DATABASE wrenchbox_homolog TO wrenchbox_app, wrenchbox_auth;
GRANT USAGE, CREATE ON SCHEMA public TO wrenchbox_app;
GRANT USAGE ON SCHEMA public TO wrenchbox_auth;
ALTER DEFAULT PRIVILEGES FOR ROLE wrenchbox_app IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wrenchbox_app;
ALTER DEFAULT PRIVILEGES FOR ROLE wrenchboxadmin IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wrenchbox_app;

\connect wrenchbox_prod
GRANT CONNECT ON DATABASE wrenchbox_prod TO wrenchbox_app, wrenchbox_auth;
GRANT USAGE, CREATE ON SCHEMA public TO wrenchbox_app;
GRANT USAGE ON SCHEMA public TO wrenchbox_auth;
ALTER DEFAULT PRIVILEGES FOR ROLE wrenchbox_app IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wrenchbox_app;
ALTER DEFAULT PRIVILEGES FOR ROLE wrenchboxadmin IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wrenchbox_app;
