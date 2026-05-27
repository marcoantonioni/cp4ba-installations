# Configurations

_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 25.1.0 -k 25.0.1

_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-multi-db.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 25.1.0 -k 25.0.1

_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai-crash-np-denyall.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 25.1.0 -k 25.0.1

_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.0
_KK=25.0.1
CONFIG_FILE=${_PTC}/env1-runtime-wfps-np.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 25.1.0 -k 25.0.1

#----------------------------------------------------------------------

_PTC=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1
_VV=25.1.1
_KK=25.0.1-IF001

## --------------
### latest version
CONFIG_FILE=${_PTC}/env1-authoring-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-authoring-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}

CONFIG_FILE=${_PTC}/env1-runtime-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


## --------------
CONFIG_FILE=${_PTC}/env1-runtime-baw-bai-perf-test.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v ${_VV} -k ${_KK}


#===================================

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
