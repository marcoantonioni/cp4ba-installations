/* AE */
CREATE DATABASE test1_bpm_aedb_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_aedb_1 to postgres;
\c test1_bpm_aedb_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* BAW */
CREATE DATABASE test1_bpm_baw_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_baw_1 to postgres;
\c test1_bpm_baw_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* ICN */
CREATE DATABASE test1_bpm_icn OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_icn to postgres;
\c test1_bpm_icn;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

/* GCD */
CREATE DATABASE test1_bpm_gcd OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_gcd to postgres;
\c test1_bpm_gcd;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE test1_bpm_gcd_tbs owner postgres location '/run/tbs/gcd';
GRANT CREATE ON TABLESPACE test1_bpm_gcd_tbs to postgres; 

/* OS1 */
CREATE DATABASE test1_bpm_os1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_os1 to postgres;
\c test1_bpm_os1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE test1_bpm_os1_tbs owner postgres location '/run/tbs/os1';
GRANT CREATE ON TABLESPACE test1_bpm_os1_tbs to postgres; 

/* DOCS */
CREATE DATABASE test1_bpm_bawdocs OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_bawdocs to postgres;
\c test1_bpm_bawdocs;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE test1_bpm_bawdocs_tbs owner postgres location '/run/tbs/docs';
GRANT CREATE ON TABLESPACE test1_bpm_bawdocs_tbs to postgres; 

/* DOS */
CREATE DATABASE test1_bpm_bawdos OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_bawdos to postgres;
\c test1_bpm_bawdos;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE test1_bpm_bawdos_tbs owner postgres location '/run/tbs/dos';
GRANT CREATE ON TABLESPACE test1_bpm_bawdos_tbs to postgres; 

/* TOS */
CREATE DATABASE test1_bpm_bawtos OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_bpm_bawtos to postgres;
\c test1_bpm_bawtos;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;
CREATE TABLESPACE VWDATA_TS owner postgres location '/run/tbs/tos';
GRANT CREATE ON TABLESPACE VWDATA_TS to postgres; 
