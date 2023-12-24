CREATE DATABASE test1_aedb_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_aedb_1 to postgres;
\c test1_aedb_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

CREATE DATABASE test1_baw_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_1 to postgres;
\c test1_baw_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

CREATE DATABASE test1icn OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1icn to postgres;
\c test1icn;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
