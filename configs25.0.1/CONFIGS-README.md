# Configurations samples

## Single namespace for Environment, DB, LDAP 

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-multi-db.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/crash-tests/env1-authoring-baw-bai-crash-np-denyall.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps-np.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-onedb-int.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps-1000.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-onedb-int-1000.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


## Different namespace for Environment, DB, LDAP 

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-extdb-authoring-wfps.properties

#1. install dbms and self signed certificates (automatically creates support namespace if not exists)
./cp4ba-install-db.sh -c ${CONFIG_FILE}

#2. create DBs (must use -f to force db creation)
./cp4ba-create-databases.sh -c ${CONFIG_FILE} -w -f

#3. install environment
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-onedb-ext.properties

#1. install dbms and self signed certificates (automatically creates support namespace if not exists)
./cp4ba-install-db.sh -c ${CONFIG_FILE}

#2. create DBs (must use -f to force db creation)
./cp4ba-create-databases.sh -c ${CONFIG_FILE} -w -f

#3. install environment
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


#----------------------------------------------------------------------


## Latest version

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw-double.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw-double-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw-no-case.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-opensearch-foundation.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-wfps.properties
# NO problema certificato !!! ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
# usare versione senza fix
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-wfps.properties
# NO problema certificato !!! ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
# usare versione senza fix
```


---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-authoring-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

---
```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001
CONFIG_FILE=${_PTC}/env1-runtime-baw-bai-perf-test.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


## Remove environments

```bash
./cp4ba-remove-namespace.sh -n cp4ba-baw-authoring-prod
./cp4ba-remove-namespace.sh -n cp4ba-baw-production

./cp4ba-remove-namespace.sh -n cp4ba-baw-authoring-bai-prod
./cp4ba-remove-namespace.sh -n cp4ba-baw-bai-production


./cp4ba-remove-namespace.sh -n cp4ba-wfps-authoring-bai-prod
./cp4ba-remove-namespace.sh -n cp4ba-wfps-bai-production

./cp4ba-remove-namespace.sh -n cp4ba-wfps-authoring-pfs-bai-prod
./cp4ba-remove-namespace.sh -n cp4ba-wfps-pfs-bai-production

./cp4ba-remove-namespace.sh -n cp4ba-wfps-authoring-pfs-prod
./cp4ba-remove-namespace.sh -n cp4ba-wfps-pfs-production

./cp4ba-remove-namespace.sh -n cp4ba-wfps-authoring-prod
./cp4ba-remove-namespace.sh -n cp4ba-wfps-production
```
