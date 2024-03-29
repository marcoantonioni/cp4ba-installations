#!/bin/bash

_me=$(basename "$0")

_CFG=""
_WAIT=false
_GENERATE_SQL_ONLY=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:wg flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        w) _WAIT=true;;
        g) _GENERATE_SQL_ONLY=true;;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -w(optional) wait db pod -g(optional) generate sql only"
  exit
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
_generateSQL () {
# $1 CP4BA_INST_DB_CR_NAME
# $2 CP4BA_INST_DB_TEMPLATE

  _DB_CR_NAME=$1
  _DB_TEMPLATE=$2
  ENV_STATS="${CP4BA_INST_OUTPUT_FOLDER}/env-statements.$RANDOM.sql"

  cat ${_DB_TEMPLATE} | sed 's/§§dbPrefix§§/'"${CP4BA_INST_ENV_FOR_DB_PREFIX}"'/g' \
    | sed 's/-\{2,\}/@@savecomment@@/g' \
    | sed 's/-/_/g' \
    | sed 's/@@savecomment@@/--/g' \
    | sed 's/§§dbBAWowner§§/'"${CP4BA_INST_DB_BAW_USER}"'/g' | sed 's/§§dbBAWowner_password§§/'"${CP4BA_INST_DB_BAW_PWD}"'/g' \
    | sed 's/§§dbBAWDOCSowner§§/'"${CP4BA_INST_DB_BAWDOCS_USER}"'/g' | sed 's/§§dbBAWDOCSowner_password§§/'"${CP4BA_INST_DB_BAWDOCS_PWD}"'/g' \
    | sed 's/§§dbBAWDOSowner§§/'"${CP4BA_INST_DB_BAWDOS_USER}"'/g' | sed 's/§§dbBAWDOSowner_password§§/'"${CP4BA_INST_DB_BAWDOS_PWD}"'/g' \
    | sed 's/§§dbBAWTOSowner§§/'"${CP4BA_INST_DB_BAWTOS_USER}"'/g' | sed 's/§§dbBAWTOSowner_password§§/'"${CP4BA_INST_DB_BAWTOS_PWD}"'/g' \
    | sed 's/§§dbICNowner§§/'"${CP4BA_INST_DB_ICN_USER}"'/g' | sed 's/§§dbICNowner_password§§/'"${CP4BA_INST_DB_ICN_PWD}"'/g' \
    | sed 's/§§dbGCDowner§§/'"${CP4BA_INST_DB_GCD_USER}"'/g' | sed 's/§§dbGCDowner_password§§/'"${CP4BA_INST_DB_GCD_PWD}"'/g' \
    | sed 's/§§dbOSowner§§/'"${CP4BA_INST_DB_OS_USER}"'/g' | sed 's/§§dbOSowner_password§§/'"${CP4BA_INST_DB_OS_PWD}"'/g' \
    | sed 's/§§dbAEowner§§/'"${CP4BA_INST_DB_AE_USER}"'/g' | sed 's/§§dbAEowner_password§§/'"${CP4BA_INST_DB_AE_PWD}"'/g' > ${ENV_STATS}

  mkdir -p ${CP4BA_INST_OUTPUT_FOLDER}
  _T_NAME="${_DB_TEMPLATE##*/}"
  _SQL_FULL_TARGET="${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-${_T_NAME}"
  cp ${ENV_STATS} ${_SQL_FULL_TARGET} 2>/dev/null
  rm ${ENV_STATS}
  echo -e "${_CLR_GREEN}SQL statements for '${_CLR_YELLOW}${_DB_CR_NAME}${_CLR_GREEN}' saved in file '${_CLR_YELLOW}${_SQL_FULL_TARGET}${_CLR_YELLOW}'${_CLR_NC}"
}

#-------------------------------
_createDatabases () {
# $1 CP4BA_INST_DB_CR_NAME
# $2 CP4BA_INST_DB_TEMPLATE

  _DB_CR_NAME=$1
  _DB_TEMPLATE=$2
  _FOUND=0

  _generateSQL ${_DB_CR_NAME} ${_DB_TEMPLATE}
  if [[ "${_GENERATE_SQL_ONLY}" = "true" ]]; then
    return 0
  fi

  _FULL_TARGET="${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-${_T_NAME}"

  if [[ "${_WAIT}" = "false" ]]; then
    _MAX_WAIT=1
    _WAIT=true
  fi
  if [[ "${_WAIT}" = "true" ]]; then
    _seconds=0
    _MAX_WAIT=1800
    until [ $_seconds -gt $_MAX_WAIT ];
    do
      resourceExist "${CP4BA_INST_SUPPORT_NAMESPACE}" "pod" "${_DB_CR_NAME}-1"
      if [ $? -eq 0 ]; then
        echo -e -n "${_CLR_GREEN}Wait for pod '${_CLR_YELLOW}"${_DB_CR_NAME}-1"${_CLR_GREEN}' created (may take minutes waiting for operators) [${_seconds}]${_CLR_NC}\033[0K\r"
        sleep 1
        ((_seconds=_seconds+1))
      else
        _FOUND=1
        if [[ $_seconds -gt 0 ]]; then
          echo ""
        fi
        break
      fi
    done
  fi

  _DONE=0
  _KO=0
  if [[ "$_FOUND" = "1" ]]; then
    _MAX_WAIT_READY=600
    echo -e "${_CLR_GREEN}Wait for pod '${_CLR_YELLOW}"${_DB_CR_NAME}-1"${_CLR_GREEN}' ready (may take minutes)${_CLR_NC}"
    _RES=$(oc wait -n ${CP4BA_INST_SUPPORT_NAMESPACE} pod/${_DB_CR_NAME}-1 --for condition=Ready --timeout="${_MAX_WAIT_READY}"s 2>/dev/null)
    _IS_READY=$(echo $_RES | grep "condition met" | wc -l)
    if [ $_IS_READY -eq 1 ]; then
      echo -e "${_CLR_GREEN}Database pod is ready, load and execute sql statements in '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_GREEN}' db server${_CLR_NC}"

      # wait for container ready
      while [ true ]
      do
        oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 mkdir -p /run/setupdb
        if [ $? -gt 0 ]; then
          echo -e -n "${_CLR_GREEN}container '${_CLR_YELLOW}postgres${_CLR_GREEN}' not ready in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_GREEN}'\033[0K\r"
          sleep 5
          echo -e -n "                                                            \033[0K\r"
        else
          break
        fi
      done

      if [ $_KO -eq 0 ]; then
        # create f.s. folders for tablespaces
        oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 mkdir -p /run/setupdb /run/tbs/gcd /run/tbs/icn /run/tbs/docs /run/tbs/dos /run/tbs/tosdata /run/tbs/tosindex /run/tbs/tosblob
        if [ $? -gt 0 ]; then
          _KO=1
          echo -e "${_CLR_RED}Error creating folders in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"        
        fi
        oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 mkdir -p /run/tbs/os1data /run/tbs/os2data /run/tbs/os3data /run/tbs/os4data /run/tbs/os5data
        if [ $? -gt 0 ]; then
          _KO=1
          echo -e "${_CLR_RED}Error creating folders in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"        
        fi
        oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 mkdir -p /run/tbs/os1index /run/tbs/os2index /run/tbs/os3index /run/tbs/os4index /run/tbs/os5index
        if [ $? -gt 0 ]; then
          _KO=1
          echo -e "${_CLR_RED}Error creating folders in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"        
        fi
        oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 mkdir -p /run/tbs/os1blob /run/tbs/os2blob /run/tbs/os3blob /run/tbs/os4blob /run/tbs/os5blob
        if [ $? -gt 0 ]; then
          _KO=1
          echo -e "${_CLR_RED}Error creating folders in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"        
        fi
      fi

      if [ $_KO -eq 0 ]; then
        # copy statement file into pod's f.s.
        oc cp ${_FULL_TARGET} ${CP4BA_INST_SUPPORT_NAMESPACE}/${_DB_CR_NAME}-1:/run/setupdb/db-statements.sql -c='postgres'
        if [ $? -gt 0 ]; then
          _KO=1
          echo -e "${_CLR_RED}Error copying SQL statements file if f.s. of pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"        
        fi
      fi

      if [ $_KO -eq 0 ]; then
        # execute sql statements
        _retry=0
        while [[ $_retry -le 10 ]]
        do
          oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} -c='postgres' ${_DB_CR_NAME}-1 psql -U postgres -f /run/setupdb/db-statements.sql 2>/dev/null 1>/dev/null
          if [ $? -gt 0 ]; then
            _KO=1
            echo -e "${_CLR_RED}Error executing SQL statements in pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}', retry...${_CLR_NC}" 
            sleep 10
          else
            _KO=0       
          fi
          ((_retry = _retry + 1))
        done        
      fi

      if [ $_KO -eq 0 ]; then
        _NUM_DB=$(cat ${_FULL_TARGET} | grep "CREATE DATABASE" | wc -l)
        echo -e "${_CLR_GREEN}Created '${_CLR_YELLOW}${_NUM_DB}${_CLR_GREEN}' databases.${_CLR_NC}"
        _DONE=1
      fi
    fi
  fi
  if [[ "$_DONE" = "0" ]]; then
    echo ""
    echo -e "${_CLR_RED}[✗] DBs NOT configured, check status of pod '${_CLR_YELLOW}${_DB_CR_NAME}-1${_CLR_RED}'${_CLR_NC}"
    oc get pod -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${_DB_CR_NAME}-1 -o wide
    echo -e ">>> ${_CLR_RED}\x1b[5mERROR\x1b[25m${_CLR_NC} <<< DB configuration terminated in error."
    echo ""
    exit 1
  fi

}

createDatabases () {
# $1: prefix key

  i=1
  _IDX_END=${CP4BA_INST_DB_INSTANCES}
  while [[ $i -le $_IDX_END ]]
  do
    _INST_ITEM="$1_$i"
    _INST_DB_CR_NAME="CP4BA_INST_DB_"$i"_CR_NAME"
    _INST_DB_TEMPLATE="CP4BA_INST_DB_"$i"_TEMPLATE"

    if [[ ! -f "${!_INST_DB_TEMPLATE}" ]]; then
      echo -e ">>> ${_CLR_RED}\x1b[5mERROR\x1b[25m${_CLR_NC} <<< SQL Statements file not found: "${!_INST_DB_TEMPLATE}
      echo ""
      exit 1
    fi
    if [[ "${!_INST_ITEM}" = "true" ]]; then
      if [[ ! -z "${!_INST_DB_CR_NAME}" ]] && [[ ! -z "${!_INST_DB_TEMPLATE}" ]]; then
        _createDatabases ${!_INST_DB_CR_NAME} ${!_INST_DB_TEMPLATE}
      else
        echo -e "${_CLR_RED}ERROR, env var '${_CLR_GREEN}${_INST_DB_CR_NAME}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES value.${_CLR_NC}"
        echo -e ">>> ${_CLR_RED}\x1b[5mERROR\x1b[25m${_CLR_NC} <<< env var '${_CLR_GREEN}${_INST_DB_CR_NAME}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES value.${_CLR_NC}"
        echo ""
        exit 1
      fi
    else
      echo -e "${_CLR_YELLOW}Warning: ${_INST_ITEM} DB '${_CLR_GREEN}${!_INST_DB_CR_NAME}${_CLR_YELLOW}' is disabled, skipping configuration${_CLR_NC}"
    fi
    ((i = i + 1))
  done  
}

echo -e "${_CLR_YELLOW}==============================================================${_CLR_NC}"

if [[ "${CP4BA_INST_DB}" = "true" ]]; then
  if [[ "${_GENERATE_SQL_ONLY}" = "false" ]]; then
    echo -e "${_CLR_GREEN}Creating databases for '${_CLR_YELLOW}${CP4BA_INST_DB_INSTANCES}${_CLR_GREEN}' db servers${_CLR_NC}"
  fi
  createDatabases "CP4BA_INST_BAW"
  createDatabases "CP4BA_INST_CONTENT"
  createDatabases "CP4BA_INST_ICN"
else
  echo -e "${_CLR_GREEN}Skipping creation of databases${_CLR_NC}"
fi
