/*
===========================================================================================
DISCLAIMER
These configurations are not indicated or intended TO be valid for production environments.
The purpose is purely educational.
===========================================================================================
*/

/*
----------------------------
Databases for BAW Authoring
----------------------------
*/

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
Db ICN 
*/
CREATE ROLE §§dbICNowner§§ PASSWORD '§§dbICNowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_icn OWNER §§dbICNowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn TO §§dbICNowner§§;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS §§dbICNowner§§ AUTHORIZATION §§dbICNowner§§;
GRANT ALL ON SCHEMA §§dbICNowner§§ TO §§dbICNowner§§;
CREATE TABLESPACE §§dbPrefix§§_icndb_tbs OWNER §§dbICNowner§§ LOCATION '/§§dbBasePath§§/tbs/icn';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_icndb_tbs TO §§dbICNowner§§; 

/* 
Db GCD 
*/
CREATE ROLE §§dbGCDowner§§ PASSWORD '§§dbGCDowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_gcd OWNER §§dbGCDowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_gcd TO §§dbGCDowner§§;
\c §§dbPrefix§§_gcd;
CREATE SCHEMA IF NOT EXISTS §§dbGCDowner§§ AUTHORIZATION §§dbGCDowner§§;
GRANT ALL ON SCHEMA §§dbGCDowner§§ TO §§dbGCDowner§§;
CREATE TABLESPACE §§dbPrefix§§_gcd_tbs OWNER §§dbGCDowner§§ LOCATION '/§§dbBasePath§§/tbs/gcd';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_gcd_tbs TO §§dbGCDowner§§; 

/* 
Db DOCS 
*/
CREATE ROLE §§dbBAWDOCSowner§§ PASSWORD '§§dbBAWDOCSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_bawdocs OWNER §§dbBAWDOCSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdocs TO §§dbBAWDOCSowner§§;
\c §§dbPrefix§§_bawdocs;
CREATE SCHEMA IF NOT EXISTS §§dbBAWDOCSowner§§ AUTHORIZATION §§dbBAWDOCSowner§§;
GRANT ALL ON SCHEMA §§dbBAWDOCSowner§§ TO §§dbBAWDOCSowner§§;
CREATE TABLESPACE §§dbPrefix§§_bawdocs_tbs OWNER §§dbBAWDOCSowner§§ LOCATION '/§§dbBasePath§§/tbs/docs';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdocs_tbs TO §§dbBAWDOCSowner§§; 

/* 
Db DOS 
*/
CREATE ROLE §§dbBAWDOSowner§§ PASSWORD '§§dbBAWDOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_bawdos OWNER §§dbBAWDOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawdos TO §§dbBAWDOSowner§§;
\c §§dbPrefix§§_bawdos;
CREATE SCHEMA IF NOT EXISTS §§dbBAWDOSowner§§ AUTHORIZATION §§dbBAWDOSowner§§;
GRANT ALL ON SCHEMA §§dbBAWDOSowner§§ TO §§dbBAWDOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_bawdos_tbs OWNER §§dbBAWDOSowner§§ LOCATION '/§§dbBasePath§§/tbs/dos';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_bawdos_tbs TO §§dbBAWDOSowner§§; 

/* 
Db CHOS 
*/
CREATE ROLE §§dbCHOSowner§§ PASSWORD '§§dbCHOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_chos OWNER §§dbCHOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_chos TO §§dbCHOSowner§§;
\c §§dbPrefix§§_chos;
CREATE SCHEMA IF NOT EXISTS §§dbCHOSowner§§ AUTHORIZATION §§dbCHOSowner§§;
GRANT ALL ON SCHEMA §§dbCHOSowner§§ TO §§dbCHOSowner§§;

/* 
Db TOS 
*/
CREATE ROLE §§dbBAWTOSowner§§ PASSWORD '§§dbBAWTOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_bawtos OWNER §§dbBAWTOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_bawtos TO §§dbBAWTOSowner§§;
\c §§dbPrefix§§_bawtos;
CREATE SCHEMA IF NOT EXISTS §§dbBAWTOSowner§§ AUTHORIZATION §§dbBAWTOSowner§§;
GRANT ALL ON SCHEMA §§dbBAWTOSowner§§ TO §§dbBAWTOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_vwdata_ts OWNER §§dbBAWTOSowner§§ LOCATION '/§§dbBasePath§§/tbs/tosdata';
CREATE TABLESPACE §§dbPrefix§§_vwindex_ts OWNER §§dbBAWTOSowner§§ LOCATION '/§§dbBasePath§§/tbs/tosindex';
CREATE TABLESPACE §§dbPrefix§§_vwblob_ts OWNER §§dbBAWTOSowner§§ LOCATION '/§§dbBasePath§§/tbs/tosblob';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwdata_ts TO §§dbBAWTOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwindex_ts TO §§dbBAWTOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwblob_ts TO §§dbBAWTOSowner§§; 

/*
Db AWS
*/
CREATE ROLE §§dbAWSowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbAWSowner_password§§';
CREATE DATABASE §§dbPrefix§§_awsdb WITH OWNER §§dbAWSowner§§ ENCODING 'UTF8';
\c §§dbPrefix§§_awsdb;
CREATE SCHEMA IF NOT EXISTS §§dbAWSowner§§ AUTHORIZATION §§dbAWSowner§§;
GRANT ALL ON SCHEMA §§dbAWSowner§§ TO §§dbAWSowner§§;


/* 
Db CONTENT 
*/
CREATE ROLE §§dbBAWCNTowner§§ PASSWORD '§§dbBAWCNTowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbPrefix§§_content OWNER §§dbBAWCNTowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_content TO §§dbBAWCNTowner§§;
\c §§dbPrefix§§_content;
CREATE SCHEMA IF NOT EXISTS §§dbBAWCNTowner§§ AUTHORIZATION §§dbBAWCNTowner§§;
GRANT ALL ON SCHEMA §§dbBAWCNTowner§§ TO §§dbBAWCNTowner§§;
CREATE TABLESPACE §§dbPrefix§§_contentdata_ts OWNER §§dbBAWCNTowner§§ LOCATION '/§§dbBasePath§§/tbs/contentdata';
CREATE TABLESPACE §§dbPrefix§§_contentindex_ts OWNER §§dbBAWCNTowner§§ LOCATION '/§§dbBasePath§§/tbs/contentindex';
CREATE TABLESPACE §§dbPrefix§§_contentblob_ts OWNER §§dbBAWCNTowner§§ LOCATION '/§§dbBasePath§§/tbs/contentblob';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_contentdata_ts TO §§dbBAWCNTowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_contentindex_ts TO §§dbBAWCNTowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_contentblob_ts TO §§dbBAWCNTowner§§; 

/* +++++++++++++++++++++ */

/*
Db AWSDOCS
*/
CREATE TABLESPACE §§dbPrefix§§_awsdocs_tbs OWNER §§dbAWSowner§§ LOCATION '/§§dbBasePath§§/tbs/awsdocs';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_awsdocs_tbs TO §§dbAWSowner§§;  
CREATE DATABASE §§dbPrefix§§_awsdocs OWNER §§dbAWSowner§§ TABLESPACE §§dbPrefix§§_awsdocs_tbs template template0 encoding UTF8 ;
\c §§dbPrefix§§_awsdocs;
CREATE SCHEMA IF NOT EXISTS §§dbAWSowner§§ AUTHORIZATION §§dbAWSowner§§;
GRANT ALL ON SCHEMA §§dbAWSowner§§ TO §§dbAWSowner§§;
SET ROLE §§dbAWSowner§§;
ALTER DATABASE §§dbPrefix§§_awsdocs SET search_path TO §§dbAWSowner§§;
SET ROLE postgres;
/* revoke connect ON DATABASE §§dbPrefix§§_awsdocs from public;
*/

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


/* ---------------------------------- */
/* OBJECT STORAGE custom */
/* ---------------------------------- */

/*
Owner for all OS
*/
CREATE ROLE §§dbOSowner§§ PASSWORD '§§dbOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;

/* 
Db OS1 
*/
CREATE DATABASE §§dbPrefix§§_os1 OWNER §§dbOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os1 TO §§dbOSowner§§;
\c §§dbPrefix§§_os1;
CREATE SCHEMA IF NOT EXISTS §§dbOSowner§§ AUTHORIZATION §§dbOSowner§§;
GRANT ALL ON SCHEMA §§dbOSowner§§ TO §§dbOSowner§§;
-- CREATE TABLESPACE §§dbPrefix§§_os1_tbs OWNER §§dbOSowner§§ LOCATION '/§§dbBasePath§§/tbs/os1';
-- GRANT CREATE ON TABLESPACE §§dbPrefix§§_os1_tbs TO §§dbOSowner§§; 

/* 
Db OS2
*/
CREATE DATABASE §§dbPrefix§§_os2 OWNER §§dbOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os2 TO §§dbOSowner§§;
\c §§dbPrefix§§_os2;
CREATE SCHEMA IF NOT EXISTS §§dbOSowner§§ AUTHORIZATION §§dbOSowner§§;
GRANT ALL ON SCHEMA §§dbOSowner§§ TO §§dbOSowner§§;


/* ---------------------------------- */
/* EXTERNAL */
/* ---------------------------------- */

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


/* 
Db AE1 (not used)
*/
CREATE DATABASE §§dbPrefix§§_ae1 OWNER §§dbAEowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_ae1 TO §§dbAEowner§§;
\c §§dbPrefix§§_ae1;
CREATE SCHEMA IF NOT EXISTS §§dbAEowner§§ AUTHORIZATION §§dbAEowner§§;
GRANT ALL ON SCHEMA §§dbAEowner§§ TO §§dbAEowner§§;

/* ---------------------------------- */
/* DECISIONS */
/* ---------------------------------- */

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
Db ADS Runtime
*/
CREATE ROLE §§dbADSRTowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbADSRTowner_password§§';
CREATE TABLESPACE §§dbPrefix§§_adsruntimedb_tbs OWNER §§dbADSRTowner§§ LOCATION '/§§dbBasePath§§/tbs/adsruntimedb';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_adsruntimedb_tbs TO §§dbADSRTowner§§;
CREATE DATABASE §§dbPrefix§§_adsruntimedb OWNER §§dbADSRTowner§§ TABLESPACE §§dbPrefix§§_adsruntimedb_tbs template template0 encoding UTF8 ;
\c §§dbPrefix§§_adsruntimedb;
CREATE SCHEMA IF NOT EXISTS ads AUTHORIZATION §§dbADSRTowner§§;
GRANT ALL ON SCHEMA ads TO §§dbADSRTowner§§;
SET ROLE §§dbADSRTowner§§;
ALTER DATABASE §§dbPrefix§§_adsruntimedb SET search_path TO §§dbADSRTowner§§;
SET ROLE postgres;
/* # revoke connect ON DATABASE §§dbPrefix§§_adsruntimedb from public;
*/

/*
Db ADS Designer
*/
CREATE ROLE §§dbADSDESowner§§ WITH INHERIT LOGIN ENCRYPTED PASSWORD '§§dbADSDESowner_password§§';
create tablespace §§dbPrefix§§_adsdesignerdb_tbs owner §§dbADSDESowner§§ location '/§§dbBasePath§§/tbs/adsdesignerdb';
grant create on tablespace §§dbPrefix§§_adsdesignerdb_tbs to §§dbADSDESowner§§;
create database §§dbPrefix§§_adsdesignerdb owner §§dbADSDESowner§§ tablespace §§dbPrefix§§_adsdesignerdb_tbs template template0 encoding UTF8 ;
\c §§dbPrefix§§_adsdesignerdb;
CREATE SCHEMA IF NOT EXISTS ads AUTHORIZATION §§dbADSDESowner§§;
GRANT ALL ON schema ads to §§dbADSDESowner§§;
SET ROLE §§dbADSDESowner§§;
ALTER DATABASE §§dbPrefix§§_adsdesignerdb SET search_path TO §§dbADSDESowner§§;
SET ROLE postgres;
/* # revoke connect on database §§dbPrefix§§_adsdesignerdb from public;
*/

/*
Db AEPlayback
*/
CREATE USER §§dbPBKowner§§ WITH PASSWORD '§§dbPBKowner_password§§';
CREATE DATABASE §§dbPrefix§§_appdb OWNER §§dbPBKowner§§;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_appdb TO §§dbPBKowner§§;

/*
Db APP
*/
CREATE USER §§dbAPPowner§§ WITH PASSWORD '§§dbAPPowner_password§§';
CREATE DATABASE §§dbPrefix§§_aaedb OWNER §§dbAPPowner§§;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aaedb TO §§dbAPPowner§§;
