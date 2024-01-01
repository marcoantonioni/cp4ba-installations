/*
Create all roles
*/
CREATE ROLE §§dbBAWowner§§ PASSWORD '§§dbBAWowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbICNowner§§ PASSWORD '§§dbICNowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbGCDowner§§ PASSWORD '§§dbGCDowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbOSowner§§ PASSWORD '§§dbOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbBAWDOCSowner§§ PASSWORD '§§dbBAWDOCSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbBAWDOSowner§§ PASSWORD '§§dbBAWDOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbBAWTOSowner§§ PASSWORD '§§dbBAWTOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbAEowner§§ PASSWORD '§§dbAEowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;

/*
Create databases, schemas and tablespaces
*/

/* BAW */
CREATE DATABASE §§dbPrefix§§_baw_1 OWNER §§dbBAWowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 to §§dbBAWowner§§;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS §§dbBAWowner§§ AUTHORIZATION §§dbBAWowner§§;
GRANT ALL ON SCHEMA §§dbBAWowner§§ to §§dbBAWowner§§;

/* ICN */
CREATE DATABASE §§dbPrefix§§_icn OWNER §§dbICNowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn to §§dbICNowner§§;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS §§dbICNowner§§ AUTHORIZATION §§dbICNowner§§;
GRANT ALL ON SCHEMA §§dbICNowner§§ to §§dbICNowner§§;
CREATE TABLESPACE icndb owner §§dbICNowner§§ location '/run/tbs/icn';
GRANT CREATE ON TABLESPACE icndb to §§dbICNowner§§; 

/* GCD */
CREATE DATABASE §§dbPrefix§§_gcd OWNER §§dbGCDowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_gcd to §§dbGCDowner§§;
\c §§dbPrefix§§_gcd;
CREATE SCHEMA IF NOT EXISTS §§dbGCDowner§§ AUTHORIZATION §§dbGCDowner§§;
GRANT ALL ON SCHEMA §§dbGCDowner§§ to §§dbGCDowner§§;
CREATE TABLESPACE §§dbPrefix§§_gcd_tbs owner §§dbGCDowner§§ location '/run/tbs/gcd';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_gcd_tbs to §§dbGCDowner§§; 

/* OS1 */
CREATE DATABASE §§dbPrefix§§_os1 OWNER §§dbOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os1 to §§dbOSowner§§;
\c §§dbPrefix§§_os1;
CREATE SCHEMA IF NOT EXISTS §§dbOSowner§§ AUTHORIZATION §§dbOSowner§§;
GRANT ALL ON SCHEMA §§dbOSowner§§ to §§dbOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_os1_tbs owner §§dbOSowner§§ location '/run/tbs/os1';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_os1_tbs to §§dbOSowner§§; 

/* DOCS */
CREATE DATABASE §§dbPrefix§§_bawdocs OWNER §§dbBAWDOCSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdocs to §§dbBAWDOCSowner§§;
\c §§dbPrefix§§_bawdocs;
CREATE SCHEMA IF NOT EXISTS §§dbBAWDOCSowner§§ AUTHORIZATION §§dbBAWDOCSowner§§;
GRANT ALL ON SCHEMA §§dbBAWDOCSowner§§ to §§dbBAWDOCSowner§§;
CREATE TABLESPACE §§dbPrefix§§_bawdocs_tbs owner §§dbBAWDOCSowner§§ location '/run/tbs/docs';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdocs_tbs to §§dbBAWDOCSowner§§; 

/* DOS */
CREATE DATABASE §§dbPrefix§§_bawdos OWNER §§dbBAWDOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdos to §§dbBAWDOSowner§§;
\c §§dbPrefix§§_bawdos;
CREATE SCHEMA IF NOT EXISTS §§dbBAWDOSowner§§ AUTHORIZATION §§dbBAWDOSowner§§;
GRANT ALL ON SCHEMA §§dbBAWDOSowner§§ to §§dbBAWDOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_bawdos_tbs owner §§dbBAWDOSowner§§ location '/run/tbs/dos';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdos_tbs to §§dbBAWDOSowner§§; 

/* TOS */
CREATE DATABASE §§dbPrefix§§_bawtos OWNER §§dbBAWTOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawtos to §§dbBAWTOSowner§§;
\c §§dbPrefix§§_bawtos;
CREATE SCHEMA IF NOT EXISTS §§dbBAWTOSowner§§ AUTHORIZATION §§dbBAWTOSowner§§;
GRANT ALL ON SCHEMA §§dbBAWTOSowner§§ to §§dbBAWTOSowner§§;
CREATE TABLESPACE vwdata_ts owner §§dbBAWTOSowner§§ location '/run/tbs/tosdata';
CREATE TABLESPACE vwindex_ts owner §§dbBAWTOSowner§§ location '/run/tbs/tosindex';
CREATE TABLESPACE vwblob_ts owner §§dbBAWTOSowner§§ location '/run/tbs/tosblob';
GRANT CREATE ON TABLESPACE vwdata_ts to §§dbBAWTOSowner§§; 
GRANT CREATE ON TABLESPACE vwindex_ts to §§dbBAWTOSowner§§; 
GRANT CREATE ON TABLESPACE vwblob_ts to §§dbBAWTOSowner§§; 

/* AE */
CREATE DATABASE §§dbPrefix§§_aedb_1 OWNER §§dbAEowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aedb_1 to §§dbAEowner§§;
\c §§dbPrefix§§_aedb_1;
CREATE SCHEMA IF NOT EXISTS §§dbAEowner§§ AUTHORIZATION §§dbAEowner§§;
GRANT ALL ON SCHEMA §§dbAEowner§§ to §§dbAEowner§§;

