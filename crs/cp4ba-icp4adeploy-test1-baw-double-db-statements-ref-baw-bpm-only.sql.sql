/*
Create all roles
*/
CREATE ROLE bawadmin PASSWORD 'dem0s' CREATEDB CREATEROLE INHERIT LOGIN;

/*
Create databases, schemas and tablespaces
*/

/* BAW */
CREATE DATABASE test1_baw_double_baw_1 OWNER bawadmin ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE test1_baw_double_baw_1 to bawadmin;
\c test1_baw_double_baw_1;
CREATE SCHEMA IF NOT EXISTS bawadmin AUTHORIZATION bawadmin;
GRANT ALL ON SCHEMA bawadmin to bawadmin;

