CREATE DATABASE §§dbPrefix§§_aedb_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aedb_1 to postgres;
\c §§dbPrefix§§_aedb_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

CREATE DATABASE §§dbPrefix§§_baw_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 to postgres;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

CREATE DATABASE §§dbPrefix§§_icn OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn to postgres;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
