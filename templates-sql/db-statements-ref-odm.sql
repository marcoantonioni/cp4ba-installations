/*
Db ODM
*/
CREATE ROLE §§dbODMowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbODMowner_password§§';
CREATE DATABASE §§dbPrefix§§_odmdb WITH OWNER §§dbODMowner§§ ENCODING 'UTF8';
/* # REVOKE CONNECT ON DATABASE §§dbPrefix§§_odmdb FROM PUBLIC;
*/
\c §§dbPrefix§§_odmdb;
CREATE SCHEMA IF NOT EXISTS §§dbODMowner§§ AUTHORIZATION §§dbODMowner§§;
GRANT ALL ON SCHEMA §§dbODMowner§§ TO §§dbODMowner§§;

/* 
Db ICN 
*/
CREATE ROLE §§dbICNowner§§ PASSWORD '§§dbICNowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_icn OWNER §§dbICNowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn TO §§dbICNowner§§;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS §§dbICNowner§§ AUTHORIZATION §§dbICNowner§§;
GRANT ALL ON SCHEMA §§dbICNowner§§ TO §§dbICNowner§§;
CREATE TABLESPACE §§dbPrefix§§_icndb_tbs OWNER §§dbICNowner§§ LOCATION '§§dbBasePath§§/tbs/icn';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_icndb_tbs TO §§dbICNowner§§; 


/* 
Db ZEN
*/
CREATE DATABASE zen;
CREATE USER zen_user;
GRANT CONNECT ON DATABASE zen TO public;
ALTER DATABASE zen OWNER TO zen_user;
GRANT ALL PRIVILEGES ON DATABASE zen TO zen_user;
CREATE SCHEMA watchdog;
ALTER SCHEMA watchdog OWNER TO zen_user;
GRANT ALL ON SCHEMA watchdog TO zen_user;
ALTER DATABASE zen SET timezone TO 'Etc/UTC';

/* 
Db IM
*/
CREATE DATABASE im;
CREATE USER im_user;
GRANT CONNECT ON DATABASE im TO public;
ALTER DATABASE im OWNER TO im_user;
GRANT ALL PRIVILEGES ON DATABASE im TO im_user;
ALTER DATABASE im SET timezone TO 'Etc/UTC';

/* 
Db BTS
*/
CREATE DATABASE bts;
CREATE USER bts_user;
GRANT CONNECT ON DATABASE im TO public;
ALTER DATABASE bts OWNER TO bts_user;
GRANT ALL PRIVILEGES ON DATABASE im TO bts_user;
ALTER DATABASE bts SET timezone TO 'Etc/UTC';


