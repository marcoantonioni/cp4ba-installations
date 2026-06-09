#!/bin/bash

#set -euo pipefail


_me=$(basename "$0")

_CFG=""
_TARGET_FOLDER="/tmp"

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
# read command line params
while getopts c:t:k flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        t) _TARGET_FOLDER=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -t target-folder"
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

_createDBCertificates () {
# $1 = certificate folder
# $2 = server name
_CERT_FOLDER=$1
_CERT_SERVER_NAME=$2

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

createCertificates () {

  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    _CERTS_FOLDER=$1

    log_debug "Creating certificates in folder '${_CERTS_FOLDER}' for service '${CP4BA_INST_DB_1_SERVICE_SSL}'"
    mkdir -p ${_CERTS_FOLDER} 2>/dev/null 1>/dev/null

    _createDBCertificates ${_CERTS_FOLDER} ${CP4BA_INST_DB_1_SERVICE_SSL}

  else
    log_error "${_CLR_RED}[✗] ERROR: createCertificates target folder or service name empty${_CLR_NC}"
    exit 1
  fi
}

#----------------------------------------
log_info "${_CLR_GREEN}Create certificates for service '${_CLR_YELLOW}${CP4BA_INST_DB_1_SERVICE_SSL}${_CLR_GREEN}'${_CLR_NC}"

createCertificates ${_TARGET_FOLDER} ${CP4BA_INST_DB_1_SERVICE_SSL}
