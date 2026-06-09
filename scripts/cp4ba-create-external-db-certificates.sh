#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
_INST_TMP_FOLDER="/tmp"
setTemporaryFolder () {
  _OK=0
  _ERR_MSG_FOLDER="is a folder"
  _ERR_MSG_PERMISSIONS=""
  if [[ ! -z "${CP4BA_INST_TMP_FOLDER}" ]]; then
    if [[ -d "${CP4BA_INST_TMP_FOLDER}" ]]; then
      if [[ -r "${CP4BA_INST_TMP_FOLDER}" ]] && [[ -w "${CP4BA_INST_TMP_FOLDER}" ]]; then 
        _OK=1
      else
        _ERR_MSG_PERMISSIONS=", you have not rights to read and/or write"
        _OK=-1
      fi
    else
      _ERR_MSG_FOLDER="is NOT a folder"
    fi

    if [[ $_OK -lt 1 ]]; then
      echo -e "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      echo -e "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
# read command line params
while getopts c:k flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit 1
fi

source "${_CFG}"

#----------------------------------------------------
_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

#----------------------------------------------------
if [[ ! -f "$_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh" ]]; then
  echo "Error, log package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-logger"
  exit 1
fi
source $_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh
if [[ -z "${CP4BA_LOGGING_ENABLED}" ]]; then 
  export CP4BA_LOGGING_ENABLED=true
fi
if [[ -z "${CP4BA_LOG_LEVEL}" ]]; then 
  export CP4BA_LOG_LEVEL="INFO"
fi
if [[ -z "${CP4BA_LOG_TO_CONSOLE}" ]]; then 
  export CP4BA_LOG_TO_CONSOLE=true
fi
if [[ -z "${CP4BA_LOG_TO_FILE}" ]]; then 
  export CP4BA_LOG_TO_FILE=false
fi
if [[ -z "${CP4BA_LOG_FILE}" ]]; then 
  export CP4BA_LOG_FILE=""
fi
if [[ -z "${CP4BA_LOG_MAX_SIZE}" ]]; then 
  export CP4BA_LOG_MAX_SIZE=$((10 * 1024 * 1024))
fi
if [[ -z "${CP4BA_LOG_BACKUP_COUNT}" ]]; then 
  export CP4BA_LOG_BACKUP_COUNT=5
fi

resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------------------------------

#--------------------------------
# Postgres instance with SSL enabled (ZEN,BTS,IM external databases)

_createDBCertificates () {

log_debug "_createDBCertificates: $1"
  
# $1 = certificate folder
# $2 = server name
_CERT_FOLDER=$1
_CERT_SERVER_NAME="${CP4BA_INST_DB_1_SERVER_NAME_SSL}"

_CERT_PASS=marco
_CERT_VERIFY="false"
_CERT_CA_PREFIX_NAME="my-ca"
_CERT_SERVER_PREFIX_NAME="my-server"
_CERT_CLIENT_PREFIX_NAME="my-client"

_CERT_ISSUER_SUBJ="/CN=my-postgres"
_CERT_SUBJ_SERVER="/CN=${_CERT_SERVER_NAME}"
_CERT_SUBJ_CLIENT="/CN=client.${_CERT_SERVER_NAME}"

# CA conf
mkdir -p ${_CERT_FOLDER}/ca.db.certs   # Signed certificates storage
touch ${_CERT_FOLDER}/ca.db.index      # Index of signed certificates
echo 01 > ${_CERT_FOLDER}/ca.db.serial # Next (sequential) serial number

# Configuration cert server
cat <<EOF > ${_CERT_FOLDER}/req.conf
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no
[ req_distinguished_name ]
C = CN
ST = MA
O = CP4BA
CN = root
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[ alt_names ]
IP.1 = 127.0.0.1
DNS.1 = ${CP4BA_INST_DB_1_CR_NAME_SSL}
DNS.2 = ${CP4BA_INST_DB_1_SERVICE_SSL}
DNS.3 = ${CP4BA_INST_DB_1_SERVICE_SSL_R}
DNS.4 = ${CP4BA_INST_DB_1_SERVER_NAME_SSL}
DNS.5 = ${CP4BA_INST_DB_1_SERVER_NAME_SSL_R}
DNS.6 = localhost

EOF

# Configuration cert client
cat <<EOF > ${_CERT_FOLDER}/req-client.conf
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no
[ req_distinguished_name ]
C = CN
ST = MA
O = CP4BAClient
CN = root
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
[ v3_req ]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = clientAuth

EOF

# CA
openssl genrsa -out ${_CERT_FOLDER}/ca.key 2048 2>/dev/null 1>/dev/null
openssl req -x509 -new -key ${_CERT_FOLDER}/ca.key -sha256 -days 36500 -out ${_CERT_FOLDER}/ca.cert -extensions 'v3_ca' -config ${_CERT_FOLDER}/req.conf 2>/dev/null 1>/dev/null

# SERVER
openssl genrsa -out ${_CERT_FOLDER}/server.key 2048 2>/dev/null 1>/dev/null
openssl req -new -sha256 -key ${_CERT_FOLDER}/server.key -out ${_CERT_FOLDER}/server-req.pem -subj "/CN=${CP4BA_INST_DB_1_CR_NAME_SSL}" -config ${_CERT_FOLDER}/req.conf 2>/dev/null 1>/dev/null
openssl x509 -req -days 36500 -sha256 -extensions v3_req -CA ${_CERT_FOLDER}/ca.cert -CAkey ${_CERT_FOLDER}/ca.key -CAcreateserial -in ${_CERT_FOLDER}/server-req.pem -out ${_CERT_FOLDER}/server.cert -extfile ${_CERT_FOLDER}/req.conf 2>/dev/null 1>/dev/null

# CLIENT
openssl genrsa -out ${_CERT_FOLDER}/client.key 2048 2>/dev/null 1>/dev/null
openssl req -new -sha256 -key ${_CERT_FOLDER}/client.key -out ${_CERT_FOLDER}/client-req.pem -subj "/CN=postgres-client" -config ${_CERT_FOLDER}/req-client.conf 2>/dev/null 1>/dev/null
openssl x509 -req -days 36500 -sha256 -extensions v3_req -CA ${_CERT_FOLDER}/ca.cert -CAkey ${_CERT_FOLDER}/ca.key -CAcreateserial -in ${_CERT_FOLDER}/client-req.pem -out ${_CERT_FOLDER}/client.cert -extfile ${_CERT_FOLDER}/req-client.conf 2>/dev/null 1>/dev/null

}

setupCertificatesAndSecrets () {
  log_debug "setupCertificatesAndSecrets"

  if [[ "${CP4BA_INST_DB_SSL_CERTIFICATE_CREATE_FOR_EXTERNAL}" != "true" ]]; then
    log_error "CP4BA_INST_DB_SSL_CERTIFICATE_CREATE_FOR_EXTERNAL must be explicitly set to true when CP4BA_INST_NAMESPACE is different from CP4BA_INST_SUPPORT_NAMESPACE"
    exit 1
  fi
  if [[ -z "${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}" ]]; then
    log_error "CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER must be set to a valid path to keep generated certificates."
    exit 1
  fi

  mkdir -p ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER} 2>/dev/null 1>/dev/null
  _createDBCertificates ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}
  log_info "Certificates created in folder ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}"

  # https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.x_cd?topic=management-configuring-external-postgresql-database-im

  export _PG_SECRET="${CP4BA_INST_DB_POSTGRES_SECRET_NAME:=my-postgresql-secret}"
  log_info "Create secret '${_CLR_YELLOW}${_PG_SECRET}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}'"
  oc delete secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${_PG_SECRET} 2>/dev/null 1>/dev/null
  oc create secret generic -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${_PG_SECRET} --from-file=${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/ 2>/dev/null 1>/dev/null

}

#-------------------------------------------------

log_msg "=============================================================="
log_info "${_CLR_GREEN}Creating secrets for external Postgres DB in namespace '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"

setupCertificatesAndSecrets

