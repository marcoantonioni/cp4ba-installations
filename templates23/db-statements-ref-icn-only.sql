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

/*
Create databases, schemas and tablespaces
*/

/* ICN */
CREATE DATABASE §§dbPrefix§§_icn OWNER §§dbICNowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_icn to §§dbICNowner§§;
\c §§dbPrefix§§_icn;
CREATE SCHEMA IF NOT EXISTS §§dbICNowner§§ AUTHORIZATION §§dbICNowner§§;
GRANT ALL ON SCHEMA §§dbICNowner§§ to §§dbICNowner§§;
CREATE TABLESPACE §§dbPrefix§§_icndb_tbs owner §§dbICNowner§§ location '/run/tbs/icn';
GRANT CREATE ON TABLESPACE §§dbPrefix§§_icndb_tbs to §§dbICNowner§§; 


