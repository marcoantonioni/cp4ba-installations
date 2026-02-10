/*
===========================================================================================
DISCLAIMER
These configurations are not indicated or intended to be valid for production environments.
The purpose is purely educational.
===========================================================================================
*/

/*
Create all roles
*/
CREATE ROLE §§dbICNowner§§ PASSWORD '§§dbICNowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbGCDowner§§ PASSWORD '§§dbGCDowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbOSowner§§ PASSWORD '§§dbOSowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE ROLE §§dbAEowner§§ PASSWORD '§§dbAEowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;

/*
Create databases, schemas and tablespaces
*/

/* ICN */
CREATE DATABASE §§dbPrefix§§_icn OWNER §§dbICNowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn to §§dbICNowner§§;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS §§dbICNowner§§ AUTHORIZATION §§dbICNowner§§;
GRANT ALL ON SCHEMA §§dbICNowner§§ to §§dbICNowner§§;
CREATE TABLESPACE §§dbPrefix§§_icndb_tbs owner §§dbICNowner§§ location '/§§dbBasePath§§/tbs/icn';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_icndb_tbs to §§dbICNowner§§; 

/* GCD */
CREATE DATABASE §§dbPrefix§§_gcd OWNER §§dbGCDowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_gcd to §§dbGCDowner§§;
\c §§dbPrefix§§_gcd;
CREATE SCHEMA IF NOT EXISTS §§dbGCDowner§§ AUTHORIZATION §§dbGCDowner§§;
GRANT ALL ON SCHEMA §§dbGCDowner§§ to §§dbGCDowner§§;
CREATE TABLESPACE §§dbPrefix§§_gcd_tbs owner §§dbGCDowner§§ location '/§§dbBasePath§§/tbs/gcd';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_gcd_tbs to §§dbGCDowner§§; 

/* AE */
CREATE DATABASE §§dbPrefix§§_aedb_1 OWNER §§dbAEowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_aedb_1 to §§dbAEowner§§;
\c §§dbPrefix§§_aedb_1;
CREATE SCHEMA IF NOT EXISTS §§dbAEowner§§ AUTHORIZATION §§dbAEowner§§;
GRANT ALL ON SCHEMA §§dbAEowner§§ to §§dbAEowner§§;

/* OS1 */
CREATE DATABASE §§dbPrefix§§_os1 OWNER §§dbOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os1 to §§dbOSowner§§;
\c §§dbPrefix§§_os1;
CREATE SCHEMA IF NOT EXISTS §§dbOSowner§§ AUTHORIZATION §§dbOSowner§§;
GRANT ALL ON SCHEMA §§dbOSowner§§ to §§dbOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_vwdata_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os1data';
CREATE TABLESPACE §§dbPrefix§§_vwindex_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os1index';
CREATE TABLESPACE §§dbPrefix§§_vwblob_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os1blob';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwdata_ts to §§dbOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwindex_ts to §§dbOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwblob_ts to §§dbOSowner§§; 

/* OS2 */
CREATE DATABASE §§dbPrefix§§_os2 OWNER §§dbOSowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_os2 to §§dbOSowner§§;
\c §§dbPrefix§§_os2;
CREATE SCHEMA IF NOT EXISTS §§dbOSowner§§ AUTHORIZATION §§dbOSowner§§;
GRANT ALL ON SCHEMA §§dbOSowner§§ to §§dbOSowner§§;
CREATE TABLESPACE §§dbPrefix§§_vwdata_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os2data';
CREATE TABLESPACE §§dbPrefix§§_vwindex_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os2index';
CREATE TABLESPACE §§dbPrefix§§_vwblob_ts owner §§dbOSowner§§ location '/§§dbBasePath§§/tbs/os2blob';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwdata_ts to §§dbOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwindex_ts to §§dbOSowner§§; 
GRANT CREATE ON TABLESPACE §§dbPrefix§§_vwblob_ts to §§dbOSowner§§; 


