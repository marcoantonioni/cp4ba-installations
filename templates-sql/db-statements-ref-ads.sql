/*
ADS Designer
*/
-- create user ads
CREATE ROLE §§dbADSDESowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbADSDESowner_password§§';
create database §§dbPrefix§§_adsdesignerdb owner §§dbADSDESowner§§ template template0 encoding UTF8 ;
\c §§dbPrefix§§_adsdesignerdb;
CREATE SCHEMA IF NOT EXISTS §§dbADSDESowner§§ AUTHORIZATION §§dbADSDESowner§§;
GRANT ALL ON schema §§dbADSDESowner§§ to §§dbADSDESowner§§;
SET ROLE §§dbADSDESowner§§;
ALTER DATABASE §§dbPrefix§§_adsdesignerdb SET search_path TO §§dbADSDESowner§§;
-- revoke connect on database §§dbPrefix§§_adsdesignerdb from public;
set ROLE postgres;


/*
ADS Runtime
*/
-- create user ads
CREATE ROLE §§dbADSRTowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbADSRTowner_password§§';
create database §§dbPrefix§§_adsruntimedb owner §§dbADSRTowner§§ template template0 encoding UTF8 ;
\c §§dbPrefix§§_adsruntimedb;
CREATE SCHEMA IF NOT EXISTS §§dbADSRTowner§§ AUTHORIZATION §§dbADSRTowner§§;
GRANT ALL ON schema §§dbADSRTowner§§ to §§dbADSRTowner§§;
CREATE EXTENSION pgcrypto SCHEMA §§dbADSRTowner§§;
SET ROLE §§dbADSRTowner§§;
ALTER DATABASE §§dbPrefix§§_adsruntimedb SET search_path TO §§dbADSRTowner§§;
-- revoke connect on database §§dbPrefix§§_adsruntimedb from public;
set ROLE postgres;

/* 
Db BAW or BAS
*/
CREATE ROLE §§dbBAWowner§§ PASSWORD '§§dbBAWowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_baw_1 OWNER §§dbBAWowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 TO §§dbBAWowner§§;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS §§dbBAWowner§§ AUTHORIZATION §§dbBAWowner§§;
GRANT ALL ON SCHEMA §§dbBAWowner§§ TO §§dbBAWowner§§;

/*
Db AE (database for runtime application engine)
*/
CREATE USER §§dbAEowner§§ WITH PASSWORD '§§dbAEowner_password§§';
CREATE DATABASE §§dbPrefix§§_aaedb OWNER §§dbAEowner§§;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aaedb TO §§dbAEowner§§;
CREATE SCHEMA IF NOT EXISTS §§dbAEowner§§ AUTHORIZATION §§dbAEowner§§;
GRANT ALL ON SCHEMA §§dbAEowner§§ TO §§dbAEowner§§;

/*
Db AEOS
*/
CREATE ROLE §§dbAEowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbAEowner_password§§';
CREATE TABLESPACE §§dbPrefix§§_aeos_tbs OWNER §§dbAEowner§§ LOCATION '/§§dbBasePath§§/tbs/aeos';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_aeos_tbs TO §§dbAEowner§§;  
CREATE DATABASE §§dbPrefix§§_aeos OWNER §§dbAEowner§§ TABLESPACE §§dbPrefix§§_aeos_tbs template template0 encoding UTF8 ;
\c §§dbPrefix§§_aeos;
CREATE SCHEMA IF NOT EXISTS §§dbAEowner§§ AUTHORIZATION §§dbAEowner§§;
GRANT ALL ON SCHEMA §§dbAEowner§§ TO §§dbAEowner§§;
SET ROLE §§dbAEowner§§;
ALTER DATABASE §§dbPrefix§§_aeos SET search_path TO §§dbAEowner§§;
SET ROLE postgres;
/* # revoke connect ON DATABASE §§dbPrefix§§_aeos from public;
*/

/*
Db App Playback (playback_server:)
*/
CREATE USER §§dbAPPowner§§ WITH PASSWORD '§§dbAPPowner_password§§';
CREATE DATABASE §§dbPrefix§§_appdb OWNER §§dbAPPowner§§;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_appdb TO §§dbAPPowner§§;
CREATE SCHEMA IF NOT EXISTS §§dbAPPowner§§ AUTHORIZATION §§dbAPPowner§§;
GRANT ALL ON SCHEMA §§dbAPPowner§§ TO §§dbAPPowner§§;


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


