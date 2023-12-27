#!/bin/bash

_me=$(basename "$0")

_CFG=""
_WAIT=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:w flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        w) _WAIT=true;;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
fi

source ${_CFG}

if [[ ! -f "${CP4BA_INST_DB_TEMPLATE}" ]]; then
  echo "SQL Statements file not found: "${CP4BA_INST_DB_TEMPLATE}
  exit 1
fi

#-------------------------------
resourceExist () {
# namespace name: $1
# resource type: $2
# resource name: $3
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------
createDatabases () {
  _FOUND=0
  if [[ "${_WAIT}" = "true" ]]; then
    _seconds=0
    _MAX_WAIT=600
    until [ $_seconds -gt $_MAX_WAIT ];
    do
      resourceExist "${CP4BA_INST_SUPPORT_NAMESPACE}" "pod" "${CP4BA_INST_DB_CR_NAME}-1"
      if [ $? -eq 0 ]; then
        echo -e -n "${_CLR_GREEN}Wait for pod '${_CLR_YELLOW}"${CP4BA_INST_DB_CR_NAME}-1"${_CLR_GREEN}' created (may take minutes) [${_seconds}]${_CLR_NC}\033[0K\r"
        sleep 1
        ((_seconds=_seconds+1))
      else
        _FOUND=1
        echo ""
        break
      fi
    done
  fi

  _DONE=0
  if [[ "$_FOUND" = "1" ]]; then
    _MAX_WAIT_READY=180
    echo -e "${_CLR_GREEN}Wait for pod '${_CLR_YELLOW}"${CP4BA_INST_DB_CR_NAME}-1"${_CLR_GREEN}' ready (may take minutes)${_CLR_NC}"
    _RES=$(oc wait -n ${CP4BA_INST_SUPPORT_NAMESPACE} pod/${CP4BA_INST_DB_CR_NAME}-1 --for condition=Ready --timeout="${_MAX_WAIT_READY}"s 2>/dev/null)
    _IS_READY=$(echo $_RES | grep "condition met" | wc -l)
    if [ $_IS_READY -eq 1 ]; then
      echo -e "${_CLR_GREEN}Database pod is ready, load and execute sql statements in '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-1${_CLR_GREEN}' db server${_CLR_NC}"
      ENV_STATS="./env-statements.sql"
      cat ${CP4BA_INST_DB_TEMPLATE} | sed 's/§§dbPrefix§§/'"${CP4BA_INST_ENV}"'/g' | sed 's/-/_/g' > ${ENV_STATS}
      oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${CP4BA_INST_DB_CR_NAME}-1 mkdir -p /run/setupdb
      oc cp ${ENV_STATS} ${CP4BA_INST_SUPPORT_NAMESPACE}/${CP4BA_INST_DB_CR_NAME}-1:/run/setupdb/db-statements.sql -c='postgres'
      oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${CP4BA_INST_DB_CR_NAME}-1 psql -U postgres -f /run/setupdb/db-statements.sql 1>/dev/null
      _NUM_DB=$(cat ${ENV_STATS} | grep "CREATE DATABASE" | wc -l)
      echo -e "${_CLR_GREEN}Created '${_CLR_YELLOW}${_NUM_DB}${_CLR_GREEN}' databases.${_CLR_NC}"
      rm ${ENV_STATS}
      _DONE=1
    fi
  fi
  if [[ "$_DONE" = "0" ]]; then
    echo ""
    echo -e "${_CLR_RED}DBs NOT configured, check status of pod '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"
    oc get pod -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-1 -o wide
    echo -e ">>> ${_CLR_RED}\x1b[5mERROR\x1b[25m${_CLR_NC} <<< DB configuration terminated."
    exit 1
    echo ""
  fi

}

echo -e "=============================================================="
if [[ "${CP4BA_INST_DB}" = "true" ]]; then
  echo -e "${_CLR_GREEN}Creating databases in '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-1${_CLR_GREEN}' db server${_CLR_NC}"
  createDatabases
else
  echo -e "${_CLR_BLUE}Skipping creation of databases${_CLR_NC}"
fi
