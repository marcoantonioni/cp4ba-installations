# Configurations

## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-baw.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-baw-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-wfps.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-wfps-pfs.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-wfps-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


## --------------
CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-authoring-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1

CONFIG_FILE=/home/$USER/cp4ba-projects/cp4ba-installations/configs25.0.1/env1-runtime-wfps-pfs-bai.properties
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -k 25.0.1


#===================================
cd cp4ba-utilities/remove-cp4ba/

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
