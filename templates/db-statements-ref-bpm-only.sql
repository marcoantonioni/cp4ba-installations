CREATE DATABASE §§dbPrefix§§_baw_1 OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_baw_1 to postgres;
\c §§dbPrefix§§_baw_1;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

CREATE DATABASE §§dbPrefix§§_gcd OWNER postgres ENCODING UTF8;
GRANT ALL PRIVILEGES ON DATABASE §§dbPrefix§§_gcd to postgres;
\c §§dbPrefix§§_gcd;
CREATE SCHEMA IF NOT EXISTS postgres AUTHORIZATION postgres;
GRANT ALL ON SCHEMA postgres to postgres;

