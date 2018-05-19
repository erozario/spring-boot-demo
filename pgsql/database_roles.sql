CREATE DATABASE demoapp WITH ENCODING 'UTF8' TEMPLATE template0;
CREATE ROLE grp_demo_app_user
  LOGIN;

\c demoapp

-- create a user for vault
CREATE ROLE vaultadmin WITH NOCREATEDB
  CREATEROLE
  ADMIN grp_demo_app_user
  LOGIN
  PASSWORD 'superinsecure';

CREATE TABLE message (
  id      BIGSERIAL PRIMARY KEY,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  message TEXT      NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO grp_demo_app_user;
GRANT USAGE, UPDATE ON ALL SEQUENCES IN SCHEMA public TO grp_demo_app_user;
