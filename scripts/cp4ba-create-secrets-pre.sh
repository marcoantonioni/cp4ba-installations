#!/bin/bash

_me=$(basename "$0")

_CFG=""
_SCRIPTS=""

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
        s) _SCRIPTS=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

source ${_CFG}

#---------------------------
# LDAP
oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LDAP_SECRET}
oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_LDAP_SECRET} \
  --from-literal=ldapUsername="cn=admin,dc=vuxprod,dc=net" \
  --from-literal=ldapPassword="passw0rd"

_USER_NAME=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.username}' | base64 -d)
_USER_PASSWORD=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.password}' | base64 -d)
# echo $_USER_NAME / $_USER_PASSWORD

#---------------------------
# FNCM
if [[ ! -z "${_USER_NAME}" ]]; then
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
    --from-literal=osDBUsername="${_USER_NAME}" \
    --from-literal=osDBPassword="${_USER_PASSWORD}" \
    --from-literal=gcdDBUsername="${_USER_NAME}" \
    --from-literal=gcdDBPassword="${_USER_PASSWORD}" \
    --from-literal=contentDBUsername="${_USER_NAME}" \
    --from-literal=contentDBPassword="${_USER_PASSWORD}" \
    --from-literal=appLoginUsername="cp4admin" \
    --from-literal=appLoginPassword="dem0s" \
    --from-literal=ltpaPassword="passw0rd" \
    --from-literal=keystorePassword="changeitchangeit"
else
  echo "Secret ibm-fncm-secret NOT created !!!"
fi

#---------------------------
# BAW
# vedi rif ibm-baw-wfs-server-db-secret
if [[ ! -z "${_USER_NAME}" ]]; then
  if [[ -z "${CP4BA_INST_BAW_1_DB_USER}" ]]; then
    CP4BA_INST_BAW_1_DB_USER="${_USER_NAME}"
    CP4BA_INST_BAW_1_DB_PWD="${_USER_PASSWORD}"
  fi
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAW_1_DB_SECRET}
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_BAW_1_DB_SECRET} \
    --from-literal=dbUser="${CP4BA_INST_BAW_1_DB_USER}" \
    --from-literal=password="${CP4BA_INST_BAW_1_DB_PWD}"
else
  echo "Secret ${CP4BA_INST_BAW_1_DB_SECRET} NOT created !!!"
fi

#---------------------------
# BAN - Navigator
oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-ban-secret
oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-ban-secret \
  --from-literal=navigatorDBUsername="${_USER_NAME}" \
  --from-literal=navigatorDBPassword="${_USER_PASSWORD}" \
  --from-literal=appLoginUsername="cp4admin" \
  --from-literal=appLoginPassword="dem0s" \
  --from-literal=keystorePassword="changeit" \
  --from-literal=ltpaPassword="changeit"

#---------------------------
# AE
oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_AE_1_AD_SECRET_NAME}
oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_AE_1_AD_SECRET_NAME} \
  --from-literal=AE_DATABASE_USER="${_USER_NAME}" \
  --from-literal=AE_DATABASE_PWD="${_USER_PASSWORD}"
