# SQL Templates

This folder contains some templates for creating databases/users/tablespaces required for the various CP4BA capabilities configurations.

Each template is processed and used when creating the Postgres DB instance (pod installation only), and the placeholders defined by '§§...§§§' are replaced with the variables defined in the main configuration's .properties file.


## Drop database and user/role

If you are reusing your Postgres instance in a pod, you can manually remove databases/users/tablespaces with the following command sequence:

```sql
DROP DATABASE IF EXISTS your_database_name;

DROP TABLESPACE IF EXISTS your_tablespace_name;

REVOKE ALL PRIVILEGES ON SCHEMA public FROM your_user_name;

DROP ROLE IF EXISTS your_user_name;
-- or
DROP USER IF EXISTS your_user_name;
```

