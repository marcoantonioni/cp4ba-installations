/*
Create all roles
*/
CREATE ROLE bawadmin PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE icn PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE gcd PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE os PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE bawdocs PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE bawdos PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE bawtos PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE ae PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;

/*
Create databases, schemas and tablespaces
*/

/* BAW */
CREATE DATABASE test1_baw_baw_1 OWNER bawadmin ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_baw_1 to bawadmin;
\c test1_baw_baw_1;
CREATE SCHEMA IF NOT EXISTS bawadmin AUTHORIZATION bawadmin;
GRANT ALL ON SCHEMA bawadmin to bawadmin;

/* ICN */
CREATE DATABASE test1_baw_icn OWNER icn ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_icn to icn;
\c test1_baw_icn;
CREATE SCHEMA IF NOT EXISTS icn AUTHORIZATION icn;
GRANT ALL ON SCHEMA icn to icn;
CREATE TABLESPACE icndb owner icn location '/run/tbs/icn';
GRANT CREATE ON TABLESPACE icndb to icn; 

/* GCD */
CREATE DATABASE test1_baw_gcd OWNER gcd ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_gcd to gcd;
\c test1_baw_gcd;
CREATE SCHEMA IF NOT EXISTS gcd AUTHORIZATION gcd;
GRANT ALL ON SCHEMA gcd to gcd;
CREATE TABLESPACE test1_baw_gcd_tbs owner gcd location '/run/tbs/gcd';
GRANT CREATE ON TABLESPACE test1_baw_gcd_tbs to gcd; 

/* OS1 */
CREATE DATABASE test1_baw_os1 OWNER os ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_os1 to os;
\c test1_baw_os1;
CREATE SCHEMA IF NOT EXISTS os AUTHORIZATION os;
GRANT ALL ON SCHEMA os to os;
CREATE TABLESPACE test1_baw_os1_tbs owner os location '/run/tbs/os1';
GRANT CREATE ON TABLESPACE test1_baw_os1_tbs to os; 

/* DOCS */
CREATE DATABASE test1_baw_bawdocs OWNER bawdocs ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_bawdocs to bawdocs;
\c test1_baw_bawdocs;
CREATE SCHEMA IF NOT EXISTS bawdocs AUTHORIZATION bawdocs;
GRANT ALL ON SCHEMA bawdocs to bawdocs;
CREATE TABLESPACE test1_baw_bawdocs_tbs owner bawdocs location '/run/tbs/docs';
GRANT CREATE ON TABLESPACE test1_baw_bawdocs_tbs to bawdocs; 

/* DOS */
CREATE DATABASE test1_baw_bawdos OWNER bawdos ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_bawdos to bawdos;
\c test1_baw_bawdos;
CREATE SCHEMA IF NOT EXISTS bawdos AUTHORIZATION bawdos;
GRANT ALL ON SCHEMA bawdos to bawdos;
CREATE TABLESPACE test1_baw_bawdos_tbs owner bawdos location '/run/tbs/dos';
GRANT CREATE ON TABLESPACE test1_baw_bawdos_tbs to bawdos; 

/* TOS */
CREATE DATABASE test1_baw_bawtos OWNER bawtos ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_bawtos to bawtos;
\c test1_baw_bawtos;
CREATE SCHEMA IF NOT EXISTS bawtos AUTHORIZATION bawtos;
GRANT ALL ON SCHEMA bawtos to bawtos;
CREATE TABLESPACE vwdata_ts owner bawtos location '/run/tbs/tosdata';
CREATE TABLESPACE vwindex_ts owner bawtos location '/run/tbs/tosindex';
CREATE TABLESPACE vwblob_ts owner bawtos location '/run/tbs/tosblob';
GRANT CREATE ON TABLESPACE vwdata_ts to bawtos; 
GRANT CREATE ON TABLESPACE vwindex_ts to bawtos; 
GRANT CREATE ON TABLESPACE vwblob_ts to bawtos; 

/* AE */
CREATE DATABASE test1_baw_aedb_1 OWNER ae ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_aedb_1 to ae;
\c test1_baw_aedb_1;
CREATE SCHEMA IF NOT EXISTS ae AUTHORIZATION ae;
GRANT ALL ON SCHEMA ae to ae;

