# Configurations samples

## Single namespace for Environment, DB, LDAP 

-o skip operators

./cp4ba-deploy-env.sh -c ${CONFIG_FILE} -l ../configs26/_cfg-production-ldap-domain.properties

### v26

#### Base
_VV=26.0.0
_KK=26.0.0

#### IF001
_VV=26.0.1
_KK=26.0.0-IF001

#### Base version overridding template values
export CP4BA_BASE_VER="${CP4BA_BASE_VER:-26.0.0}"
export CP4BA_INST_APPVER="${CP4BA_BASE_VER}"

#### Authoring envs

last test: 20260806
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260806
```bash
# !!!
export CP4BA_INST_GIT_TOKEN="your-token"

_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw-cicd.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260806
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260806
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-ae.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260806
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260717
```bash

# !!!
export CP4BA_INST_GENAI_ENABLED="true"
export CP4BA_INST_GENAI_WX_APIKEY="...."
export CP4BA_INST_GENAI_WX_PRJ_ID="...."

_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw-genai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260720
```bash
export CP4BA_INST_GENAI_ENABLED="true"
export CP4BA_INST_GENAI_WX_APIKEY="...."
export CP4BA_INST_GENAI_WX_PRJ_ID="...."

_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-authoring-baw-pfs-genai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


#### Runtime envs

last test: 20260717
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-runtime-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260717
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-runtime-os-bai-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

last test: 20260717
```bash
_VV=26.0.0
_KK=26.0.0
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs26
CONFIG_FILE=${_PTC}/env1-runtime-opensearch-foundation.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

#### Configuration Validation

##### v26

last validation: 20260717
```bash
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-baw-bai-ae.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-baw-bai-nocpeinit.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-baw-bai.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-baw.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-baw-genai.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-authoring-wfps-pfs-bai.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-runtime-baw-bai.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-runtime-opensearch-foundation.properties
./cp4ba-validate-configurations.sh -c ../configs26/env1-runtime-os-bai-pfs.properties
```

##### v25.0.1

last validation: 20260717
```bash
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-bai-onedb-ext.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-bai-onedb-int-1000.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-bai-onedb-int.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-bai-pg17.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw-multi-db.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-baw.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-wfps-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-wfps-pfs-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-wfps-pfs.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-authoring-wfps.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-extdb-authoring-wfps.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw-bai-perf-test.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw-double-pfs.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw-double.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw-no-case.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-baw.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-opensearch-foundation.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps-1000.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps-np.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps-pfs-bai.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps-pfs.properties
./cp4ba-validate-configurations.sh -c ../configs25.0.1/env1-runtime-wfps.properties
```

##### v25.0.0

last validation: 20260717
```bash
./cp4ba-validate-configurations.sh -c ../configs25/env1-baw2.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-baw-double.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-baw.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-demo-wfps-pfs-baw-liveinst.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-demo-wfps-pfs-baw.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-starter-all-but-adp.properties
./cp4ba-validate-configurations.sh -c ../configs25/env1-starter-only-baw.properties
```

### v25

#### Authoring envs

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
CONFIG_FILE=${_PTC}/env1-authoring-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-multi-db.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-onedb-int.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

#### Runtime envs

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
CONFIG_FILE=${_PTC}/env1-runtime-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps-np.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps-1000.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-onedb-int-1000.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```

#### Crash tests induced

```bash
_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/crash-tests/env1-authoring-baw-bai-crash-np-denyall.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}
```


## Different namespace for Environment, DB, LDAP 

Steps to create DB/LDAP in an external namespace.

File env1-extdb-authoring-wfps.properties is configured with different namespace for DB/LDAP.
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

Same scenario with external DB/LDAP with a single DB
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

## v25 with fix-pack

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
