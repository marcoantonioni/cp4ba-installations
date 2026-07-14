CREATE ROLE §§dbCUSTOMowner§§ PASSWORD '§§dbCUSTOMowner_password§§' CREATEDB CREATEROLE INHERIT LOGIN;
CREATE DATABASE §§dbCUSTOMname§§ OWNER §§dbCUSTOMowner§§ ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbCUSTOMname§§ TO §§dbCUSTOMowner§§;
\c §§dbCUSTOMname§§;
CREATE SCHEMA IF NOT EXISTS §§dbCUSTOMowner§§ AUTHORIZATION §§dbCUSTOMowner§§;
GRANT ALL ON SCHEMA §§dbCUSTOMowner§§ TO §§dbCUSTOMowner§§;

/*
Db Model Gateway
*/
CREATE USER §§dbMGowner§§ WITH PASSWORD '§§dbMGowner_password§§';
CREATE DATABASE §§dbPrefix§§_modelgateway; 
GRANT CONNECT ON DATABASE §§dbPrefix§§_modelgateway TO public;
ALTER DATABASE §§dbPrefix§§_modelgateway OWNER TO §§dbMGowner§§;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_modelgateway TO §§dbMGowner§§;
ALTER DATABASE §§dbPrefix§§_modelgateway SET timezone TO 'Etc/UTC';
