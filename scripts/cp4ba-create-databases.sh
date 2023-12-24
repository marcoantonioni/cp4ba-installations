#!/bin/bash

_me=$(basename "$0")

_CFG=""
_STATEMENTS=""
_WAIT=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:s:w flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        s) _STATEMENTS=${OPTARG};;
        w) _WAIT=true;;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_STATEMENTS}" ]]; then
  echo "usage: $_me -c path-of-config-file -s sql-statements-file"
  exit
fi

if [[ ! -f "${_STATEMENTS}" ]]; then
  echo "SQL Statements file not found: "${_STATEMENTS}
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
fi
source ${_CFG}

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
    until [ $_seconds -gt 300 ];
    do
      resourceExist "${CP4BA_INST_SUPPORT_NAMESPACE}" "pod" "${CP4BA_INST_DB_CR_NAME}-1"
      if [ $? -eq 0 ]; then
        echo -e -n "${_CLR_GREEN}wait for pod '${_CLR_YELLOW}"${CP4BA_INST_DB_CR_NAME}-1"${_CLR_GREEN}' $_seconds${_CLR_NC}\033[0K\r"
        sleep 1
        ((_seconds=_seconds+1))
      else
        _FOUND=1
        echo ""
        break
      fi
    done
  fi

  if [[ ! -z "${_USER_NAME}" ]]; then
    oc rsh -c='postgres' ${CP4BA_INST_DB_CR_NAME}-1 mkdir -p /run/setupdb
    oc cp ${_STATEMENTS} ${CP4BA_INST_DB_CR_NAME}-1:/run/setupdb/db-statements.sql -c='postgres'
    oc rsh -c='postgres' ${CP4BA_INST_DB_CR_NAME}-1 psql -U postgres -f /run/setupdb/db-statements.sql
  fi
  if [[ $_FOUND = 0 ]]; then
    echo ""
    echo -e ">>> \x1b[5mWARNING\x1b[25m <<<"
    echo "Rerun this script after db '${CP4BA_INST_DB_CR_NAME}' setup."
    echo "" 
  fi

}

echo -e "#==========================================================="
echo -e "${_CLR_GREEN}Creating databases in '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-1${_CLR_GREEN}' db server${_CLR_NC}"
createDatabases