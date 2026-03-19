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
CREATE ROLE §§dbBAWowner§§ PASSWORD '§§dbBAWowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;

/*
Create databases, schemas and tablespaces
*/

/* BAW */
CREATE DATABASE §§dbPrefix§§_baw_1 OWNER §§dbBAWowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 to §§dbBAWowner§§;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS §§dbBAWowner§§ AUTHORIZATION §§dbBAWowner§§;
GRANT ALL ON SCHEMA §§dbBAWowner§§ to §§dbBAWowner§§;

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

