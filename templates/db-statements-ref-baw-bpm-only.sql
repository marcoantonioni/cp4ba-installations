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

