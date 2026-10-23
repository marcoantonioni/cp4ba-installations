#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_USER_ROLES_FILENAME=""

#_USER_MAIL="rpaadmin@vuxrpaprod.net"

_USER_ADMIN_NAME=""
_USER_ADMIN_PWD=""
_USER_CPADMIN=0

_USER_NAME=""
_USER_MAIL=""
_USER_PWD=""

LIST_OF_USERS=()
_LIST_USERS_DETAILS=()
_ROLES_BY_NAME=()
_ROLES_BY_ID=()
_USER_ROLES=""



#-----------------------------------------------------------
# TEST:
# export CP4BA_INST_NAMESPACE="cp4ba-rpa-34-managed" 
# ./cp4ba-rpa-configure-roles.sh -c ../configs26/env1-runtime-rpa-managed.properties -r /tmp/rpa/user-roles -u rpaadmin -p dem0s


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
      log_error "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      log_error "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}


usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me$
    -c full-path-to-config-file
       (eg: '../configs/env1.properties'){_CLR_NC}
    -r full-path-to-users-roles-file
    -u admin-user-name
    -p password-user-name
    -s sys-login-use-cpadmin-via-ocp-secret
    "
}

#--------------------------------------------------------
# read command line params
while getopts c:r:u:p:s flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        r) _USER_ROLES_FILENAME=${OPTARG};;
        u) _USER_ADMIN_NAME=${OPTARG};;
        p) _USER_ADMIN_PWD=${OPTARG};;
        s) _USER_CPADMIN=1;;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_USER_ROLES_FILENAME}" ]]; then
  usage
  exit 1
fi


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

if [[ ! -f "${_CFG}" ]]; then
  echo "Error config file '${_CFG}' not found !"
  echo "example:"
  echo "export _CFG=./env1-rpa1.properties"
  echo "./$_me"
  exit 1
fi

source "${_CFG}" 2>/dev/null 1>/dev/null

namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2>/dev/null | grep $1 2>/dev/null | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#------------------------------------
# 
getRoleIdByRoleName () {
  _KEY=$(sed 's/ //g' <<<"$1")
  for index in "${!_ROLES_BY_NAME[@]}"; do
    role=$(sed 's/ //g' <<<"${_ROLES_BY_NAME[index]}")
    #echo "key: $_KEY - role: $role"
    if [[ "${role}" == "${_KEY}" ]]; then
      #echo "$index - $role"
      return $index
    fi
  done      
  return -1
}

loadUsersRolesFromFile () {
  _FILE_USERS="$1"
  log_info "${_CLR_GREEN}Loading users from file '${_CLR_YELLOW}${_FILE_USERS}${_CLR_GREEN}'${_CLR_NC}"

  IFS=$'\n'
  LIST_OF_USERS=($(cat "${_FILE_USERS}" | sed 's/\r//g'))

}

teamsList () {
    curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/team/?offset=0&limit=1000&search=&asc=false&orderBy=name&include=Roles&all=true&includeImplicitRoles=true" | jq .

}

userDetails () {
  _USER_NAME="$1"
  unset _USER_DETAILS
  _USER_DETAILS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user?offset=0&limit=1000&search=${_USER_NAME}&deactivatedOnly=false")
}

usersList () {
  _LIST_USERS_DETAILS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user?offset=0&limit=1000&search=&asc=true&orderBy=name&include=ModifiedBy,Tenant&deactivatedOnly=false")
}

#GET
#	https://cpd-cp4ba-rpa-34-managed.apps.itz-18gwkt.infra01-lb.fra02.techzone.ibm.com/rpa/api/v1.0/en-US/user/d2c6e0d4-3fe2-4527-8710-ad2ea94dff0c/roles?all=true
#  &search=&asc=true&orderBy=name
#GET
#	https://cpd-cp4ba-rpa-34-managed.apps.itz-18gwkt.infra01-lb.fra02.techzone.ibm.com/rpa/api/v1.0/en-US/user/d2c6e0d4-3fe2-4527-8710-ad2ea94dff0c/roles?offset=0&limit=10&search=&asc=true&orderBy=name

userRoles () {
  _USER_ID="$1"
  _USER_ROLES=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user/"${_USER_ID}"/roles?all=true")
}

onboardUsersAndConfigureRoles () {
  for indexUserRoles in "${!LIST_OF_USERS[@]}"; do
    lineUserRoles="${LIST_OF_USERS[indexUserRoles]}"
    lineUserRoles=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${lineUserRoles})
    if [[ ! -z "${lineUserRoles}" ]]; then
      if [[ ! "$lineUserRoles" == "#"* ]]; then
        IFS=":" read -r userName roles <<< "${lineUserRoles}"
        IFS=',' read -r -a userRoles <<< "${roles}"
        userName=$(sed 's/ //g' <<<${userName})

        _USER_INFO=$(jq '.results[] | select(.name=="'${userName}'")' <<<${_RPA_USERS_LIST})
        if [[ ! -z "${_USER_INFO}" ]]; then
          _USER_NAME=$(echo ${_USER_INFO} | jq .name | sed 's/"//g')
          _USER_DISTINGUISHED_NAME=$(echo ${_USER_INFO} | jq .distinguishedName | sed 's/"//g')
          _USER_EMAIL=$(echo ${_USER_INFO} | jq .email | sed 's/"//g')
          _USER_HAS_ACCESS=$(echo ${_USER_INFO} | jq .hasAccess | sed 's/"//g')

          _rolesBuffer=""
          _inserted=0
          for index in "${!userRoles[@]}"; do
            role="${userRoles[index]}"
            role=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${role})
            getRoleIdByRoleName "${role}"
            roleIdx=$?
            if [[ $roleIdx -ge 0 ]]; then
              roleId="${_ROLES_BY_ID[roleIdx]}"
              #echo "  role-> [$index] '${role}' / '${roleId}'"
              if [[ $_inserted -gt 0 ]]; then
                _rolesBuffer="${_rolesBuffer},"
              fi            
              _rolesBuffer="${_rolesBuffer}\"${roleId}\""
              _inserted=1
            fi
          done
          RESPONSE=""
          if [[ "${_USER_HAS_ACCESS}" == "false" ]]; then
            echo "Onboard and configuring: '$userName' with [${#userRoles[@]}] roles [${userRoles[@]}]"

            _RECORD='{
              "roles": ['${_rolesBuffer}'],
              "teams": [],
              "users": [
                {
                  "name": "'${_USER_NAME}'",
                  "email": "'${_USER_EMAIL}'",
                  "distinguishedName": "'${_USER_DISTINGUISHED_NAME}'"
                }
              ]
            }'
            #echo $_RECORD | jq .
            RESPONSE=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
                        -X POST -d "${_RECORD}" "${PAK_HOST}/rpa/api/v1.0/en-US/user/import")

          else
            echo "Configure '${userName}' with [${#userRoles[@]}] roles [${userRoles[@]}]"
            _RECORD='{
              "roles": ['${_rolesBuffer}']
            }'
            userDetails "${_USER_NAME}"
            _USER_ID=$(echo $_USER_DETAILS | jq .results[0].id | sed 's/"//g')
            if [[ ! -z "${_USER_ID}" ]]; then
              RESPONSE=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
                          -X PATCH -d "${_RECORD}" "${PAK_HOST}/rpa/api/v1.0/en-US/user/$_USER_ID/roles")
            fi
          fi

        else
          echo "User '${userName}' not in users domains, skip configuration."
        fi
      fi
    fi
  done
  unset IFS

}

checkConfiguration () {
  _FILE_USERS="$1"
  if [[ ! -f "${_FILE_USERS}" ]]; then
    log_error "ERROR Users roles file '${_FILE_USERS}' not found !!!"
    exit 1
  fi

  namespaceExist "${CP4BA_INST_RPA_NAMESPACE}"
  if [ $? -eq 0 ]; then
    log_error "Namespace '${_CLR_YELLOW}${CP4BA_INST_RPA_NAMESPACE}${_CLR_GREEN}' doesn't exists."
    exit 1
  fi

}

#------------------------------------------------------------------------
_USER_IAM_TK=""
_USER_ACCESS_TK=""
_OIDC_TK=""
_TENANT_ID=""
_RPA_ACCESS_TK=""
_ZEN_TK=""
CONSOLE_HOST=""
PAK_HOST=""


loginAsDeploymentAdmin () {

  _ROUTE_NAME="platform-id-provider"

  # get pak admin username / password
  _USER_ADMIN_NAME=$(oc get secret platform-auth-idp-credentials -n ${CP4BA_INST_RPA_NAMESPACE} -o jsonpath='{.data.admin_username}' | base64 -d)
  _USER_ADMIN_PWD=$(oc get secret platform-auth-idp-credentials -n ${CP4BA_INST_RPA_NAMESPACE} -o jsonpath='{.data.admin_password}' | base64 -d)

  # echo "${_USER_ADMIN_NAME} / ${_USER_ADMIN_PWD}"

  CONSOLE_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  PAK_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} cpd -o jsonpath="{.spec.host}")

  # echo "$PAK_HOST"
  # echo "$CONSOLE_HOST"

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
              -d "grant_type=password&username=${_USER_ADMIN_NAME}&password=${_USER_ADMIN_PWD}&scope=openid" ${CONSOLE_HOST}/idprovider/v1/auth/identitytoken)
  _USER_IAM_TK=$(echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_USER_IAM_TK}" ]]; then
    echo "Error identityToken: $_PAYLOAD"
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "username:${_USER_ADMIN_NAME}" -H "iam-token: $_USER_IAM_TK" $PAK_HOST/v1/preauth/validateAuth)
  _USER_ACCESS_TK=$(echo "${_PAYLOAD}" | jq -r .accessToken 2>/dev/null)
  if [[ -z "${_USER_ACCESS_TK}" ]]; then
    echo "Error validateAuth: $_PAYLOAD"
    exit 1              
  fi

  _ZEN_TK=$(curl -sk "${PAK_HOST}/v1/preauth/validateAuth" -H "username:${_USER_ADMIN_NAME}" -H "iam-token: ${_USER_IAM_TK}" | jq -r .accessToken)
  # echo "${_ZEN_TK}"

  _ACTION="usermgmt/v2/usermgmt/users"

  RESPONSE=$(curl -sk -H "Authorization: Bearer ${_ZEN_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' -X GET "${PAK_HOST}/${_ACTION}?include_groups=true&offset=0&limit=25&search_str=${_USER_ADMIN_NAME}&include_users_count=false&includeAll=true")
  _ORIG_ROLES=$(echo ${RESPONSE} | jq .[].user_roles | sed 's/\[//g' | sed 's/\]//g' | sed 's/ //g' | sed '/^$/d')

  echo "Deployment admin user:${_USER_ADMIN_NAME}, roles: ${_ORIG_ROLES}"

}

loginAsRpaAdmin () {

  if [[ -z "${_USER_ADMIN_NAME}" ]] || [[ -z "${_USER_ADMIN_PWD}" ]]; then
    log_error "Missing admin user name or password"
    usage
    exit 1
  fi

  _ROUTE_NAME="platform-id-provider"

  CONSOLE_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  PAK_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} cpd -o jsonpath="{.spec.host}")

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
              -d "grant_type=password&username="${_USER_ADMIN_NAME}"&password="${_USER_ADMIN_PWD}"&scope=openid" $CONSOLE_HOST/idprovider/v1/auth/identitytoken)
  _USER_IAM_TK=$(echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_USER_IAM_TK}" ]]; then
    echo "Error identityToken: $_PAYLOAD"
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "username:${_USER_ADMIN_NAME}" -H "iam-token: $_USER_IAM_TK" $PAK_HOST/v1/preauth/validateAuth)
  _USER_ACCESS_TK=$(echo "${_PAYLOAD}" | jq -r .accessToken 2>/dev/null)
  if [[ -z "${_USER_ACCESS_TK}" ]]; then
    echo "Error validateAuth: $_PAYLOAD"
    exit 1              
  fi

  _RPA_USER_INFO=$(curl -ks --cookie "ibm-private-cloud-session=$_USER_ACCESS_TK" $PAK_HOST/rpa/api/zen-token-login)

  #echo "User info------------------------------------"
  #echo $_RPA_USER_INFO | jq .
  #echo "---------------------------------------------"
  
  _OIDC_TK=$(echo $_RPA_USER_INFO | jq -r .oidcAccessToken)
  
  _TENANT_ID=$(echo $_RPA_USER_INFO | jq -r .tenants[0].id)

  if [[ -z "${_OIDC_TK}" ]]; then
    echo "Error OIDC Token: $_RPA_USER_INFO"
    exit 1              
  fi
  if [[ -z "${_TENANT_ID}" ]]; then
    echo "Error Tenant ID: $_RPA_USER_INFO"
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded" -d grant_type=password --cookie "ibm-private-cloud-session=$_USER_ACCESS_TK" -H "tenantId:$_TENANT_ID" -H "oidc-access-token:$_OIDC_TK" $PAK_HOST/rpa/api/v1.0/token)

  _RPA_ACCESS_TK=$( echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_RPA_ACCESS_TK}" ]]; then
    echo "Error RPA access token: $_RPA_USER_INFO"
    exit 1              
  fi

  userDetails "${_USER_ADMIN_NAME}"
  _USER_ID=$(echo $_USER_DETAILS | jq .results[0].id | sed 's/"//g')
  userRoles "${_USER_ID}"
  _IS_PLATFORM_ADMIN=$(echo "${_USER_ROLES}" | jq .results[].name | grep "Administrator" | wc -l)

  if [[ ${_IS_PLATFORM_ADMIN} -lt 1 ]]; then
    log_warning "Warning user '${_USER_ADMIN_NAME}' is not a platform/tenant admin user."
    exit 1
  else
    log_info "User '${_USER_ADMIN_NAME}' is a platform/tenant admin user."
  fi
}

_RPA_USERS_LIST="{}"
rpaLoadUsers () {
  _RESULT_LIMIT=1000
  _RPA_USERS_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user/import?offset=0&limit=${_RESULT_LIMIT}&search=vux&asc=true&orderBy=DisplayName")
}

rpaLoadRoles () {
  _RPA_ROLES_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/role?offset=0&limit=10&search=&asc=true&orderBy=name")

  _outFileRoleNames="${_INST_TMP_FOLDER}/list-of-roleNames-$USER-$RANDOM"
  _outFileRoleIds="${_INST_TMP_FOLDER}/list-of-roleIds-$USER-$RANDOM"
  rm $_outFileRoleNames 2>/dev/null 1>/dev/null
  rm $_outFileRoleIds 2>/dev/null 1>/dev/null

  jq -c '.results[].name' <<<${_RPA_ROLES_LIST} | sed 's/"//g' >> $_outFileRoleNames
  jq -c '.results[].id' <<<${_RPA_ROLES_LIST} | sed 's/"//g' >> $_outFileRoleIds

  # Role names
  index=0
  while read line; do
    _ROLES_BY_NAME[index]="$line"
    index=$((index + 1))
  done < $_outFileRoleNames  

  # Roles IDs
  index=0
  while read line; do
    _ROLES_BY_ID[index]="$line"
    index=$((index + 1))
  done < $_outFileRoleIds  

  rm $_outFileRoleNames 2>/dev/null 1>/dev/null
  rm $_outFileRoleIds 2>/dev/null 1>/dev/null

}

_RPA_BOTS_LIST="{}"
rpaBotsList () {
  _RPA_BOTS_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v2.0/workspace/${_WORKSPACE_ID}/bots")  
}

testApis () {
  echo "Test APIs ----------------------------------------------------"


  _TENANT_NAME="ibm"

  loginAsRpaAdmin

  # Tenant by name
  _TENANT_ID=$(curl -sk -X GET ${PAK_HOST}/rpa/api/v2.0/account/tenant?username=${_USER_MAIL} | jq '.[] | select(.name == "'${_TENANT_NAME}'")' | jq .id | sed 's/"//g')
  echo " ${_TENANT_NAME} / ${_TENANT_ID}"

  # List of Regions
  echo "Regions:"
  curl -sk -X GET ${PAK_HOST}/rpa/api/v2.0/configuration/regions | jq .

  # API URL od on-premise region
  echo "On-premise regions"
  curl -sk -X GET ${PAK_HOST}/rpa/api/v2.0/configuration/regions | jq '.[] | select(.name == "on-premise")' | jq .apiUrl | sed 's/"//g'

  # Workspace (Tenant)
  _WORKSPACE=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET ${PAK_HOST}/rpa/api/v2.0/workspace)
  _WORKSPACE_ID=$(echo "${_WORKSPACE}" | jq .[].id | sed 's/"//g')
  _WORKSPACE_NAME=$(echo "${_WORKSPACE}" | jq .[].name | sed 's/"//g')
  echo Workspace: "${_WORKSPACE_NAME} - ${_WORKSPACE_ID}"

  # Workspace info
  _WORKSPACE=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET ${PAK_HOST}/rpa/api/v2.0/tenant/${_WORKSPACE_ID})
  _WORKSPACE_ID=$(echo "${_WORKSPACE}" | jq .id | sed 's/"//g')
  echo "Workspace info"
  echo ${_WORKSPACE} | jq .

  # projects list
  _PROJECTS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v2.0/workspace/${_WORKSPACE_ID}/projects")
  _PRJ_ID=$(echo ${_PROJECTS} | jq .[0].id | sed 's/"//g')
  _PRJ_UNIQUE_ID=$(echo ${_PROJECTS} | jq .[0].uniqueId | sed 's/"//g')

  echo "Project: ${_PRJ_UNIQUE_ID} / ${_PRJ_ID}"

  # process list
  echo "Process list:"
  curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v2.0/workspace/${_WORKSPACE_ID}/process" | jq .

  # Bots list
  echo "-----------------------------------------"
  echo "Bots list:"
  rpaBotsList
  echo "${_RPA_BOTS_LIST}" | jq .


}

rpaConfigureRoles () {

  # checkConfiguration "${_USER_ROLES_FILENAME}"

  if [[ $_USER_CPADMIN -eq 0 ]]; then
    loginAsRpaAdmin
  else
    loginAsDeploymentAdmin
  fi
exit
  # testApis

# lista tenant
# selezione tenent ????
  
  #teamsList
  #usersList

  rpaLoadUsers
  rpaLoadRoles

  loadUsersRolesFromFile "${_USER_ROLES_FILENAME}"

  onboardUsersAndConfigureRoles
}

echo "=============================================================="
log_info "${_CLR_GREEN}Configure roles for RPA tenants in namespace '${_CLR_YELLOW}${CP4BA_INST_RPA_NAMESPACE}${_CLR_GREEN}'"
rpaConfigureRoles

exit 0
