/* AE */
CREATE DATABASE §§dbPrefix§§_aedb_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aedb_1 to postgres;
\c §§dbPrefix§§_aedb_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* BAW */
CREATE DATABASE §§dbPrefix§§_baw_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 to postgres;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* ICN */
CREATE DATABASE §§dbPrefix§§_icn OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn to postgres;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* GCD */
CREATE DATABASE §§dbPrefix§§_gcd OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_gcd to postgres;
\c §§dbPrefix§§_gcd;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE §§dbPrefix§§_gcd_tbs owner postgres location '/run/tbs/gcd';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_gcd_tbs to postgres; 

/* OS1 */
CREATE DATABASE §§dbPrefix§§_os1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os1 to postgres;
\c §§dbPrefix§§_os1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE §§dbPrefix§§_os1_tbs owner postgres location '/run/tbs/os1';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_os1_tbs to postgres; 

/* DOCS */
CREATE DATABASE §§dbPrefix§§_bawdocs OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdocs to postgres;
\c §§dbPrefix§§_bawdocs;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE §§dbPrefix§§_bawdocs_tbs owner postgres location '/run/tbs/docs';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdocs_tbs to postgres; 

/* DOS */
CREATE DATABASE §§dbPrefix§§_bawdos OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdos to postgres;
\c §§dbPrefix§§_bawdos;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE §§dbPrefix§§_bawdos_tbs owner postgres location '/run/tbs/dos';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdos_tbs to postgres; 

/* TOS */
CREATE DATABASE §§dbPrefix§§_bawtos OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawtos to postgres;
\c §§dbPrefix§§_bawtos;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE VWDATA_TS owner postgres location '/run/tbs/tos';
GRANT CREATE ON TABLESPACE VWDATA_TS to postgres; 
