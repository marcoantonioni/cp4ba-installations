#!/bin/bash

_me=$(basename "$0")

_CFG=""
_ERROR=0

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:s: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

source ${_CFG}

echo -e "#==========================================================="
echo -e "${_CLR_GREEN}Creating PVCs in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

#---------------------------
# icn-pluginstore
echo -e "PVC '${_CLR_YELLOW}icn-pluginstore${_CLR_NC}'"

cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: icn-pluginstore
  namespace: "${CP4BA_INST_NAMESPACE}"
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  storageClassName: "${CP4BA_INST_SC_FILE}"
EOF

#---------------------------
# icn-cfgstore
echo -e "PVC '${_CLR_YELLOW}icn-cfgstore${_CLR_NC}'"

cat <<EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: icn-cfgstore
  namespace: "${CP4BA_INST_NAMESPACE}"
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  storageClassName: "${CP4BA_INST_SC_FILE}"
EOF
