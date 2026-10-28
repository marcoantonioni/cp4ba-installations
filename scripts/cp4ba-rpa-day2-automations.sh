#!/usr/bin/env bash

_me=$(basename "$0")

_USER_ADMIN_NAME=""
_USER_ADMIN_PWD=""

_USER_ROLES_FILENAME=""
_TENANTS_FILENAME=""

_USER_IAM_TK=""
_USER_ACCESS_TK=""
_OIDC_TK=""
_TENANT_ID=""
_TENANT_NAME=""
_USE_TENANT_NAME=""

_TENANT_CODE=""

_RPA_ACCESS_TK=""
_ZEN_TK=""
_PAK_HOST=""

_USER_DETAILS="{}"
_USER_ROLES="{}"
_ROLES_BY_ID=()
_ROLES_BY_NAME=()
_RPA_BOTS_LIST="{}"

LIST_OF_USERS=""
LIST_OF_TENANTS=""

# ---------------------------------------------------------------------------
# Global result variables (populated by each API function)
# ---------------------------------------------------------------------------
_RPA_RESULT_USERS=""
_RPA_RESULT_ROLES=""
_RPA_RESULT_TEAMS=""
_RPA_RESULT_TENANTS=""
_RPA_RESULT_SUSPENDED_TENANTS=""
_RPA_RESULT_NEW_TENANT=""
_RPA_RESULT_CREDENTIALS=""
_RPA_RESULT_CREDENTIAL_POOLS=""
_RPA_RESULT_COMPUTERS=""
_RPA_RESULT_COMPUTER_GROUPS=""
_RPA_RESULT_PROJECTS=""
_RPA_RESULT_BOTS=""

_RPA_LOCALE="${_RPA_LOCALE:-en-US}"
_RPA_ACCOUNT_INFO=""

_RPA_NEW_USER=""
_RPA_NEW_TEAM=""
_RPA_NEW_CREDENTIAL=""
_RPA_NEW_COMPUTER_GROUP=""
_RPA_NEW_CREDS_POOL=""
_RPA_NEW_PROJECT=""
_RPA_NEW_BOT=""

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
    -f fill-path-to-tenants-file
    -u admin-user-name
    -p password-user-name
    -s sys-login-use-cpadmin-via-ocp-secret
    -k command [addtenants | removetenants | listtenants | addusers | removeusers]
    "
}

#--------------------------------------------------------
# read command line params
while getopts c:r:t:f:u:p:k:s flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        k) _CMD=${OPTARG};;
        r) _USER_ROLES_FILENAME=${OPTARG};;
        f) _TENANTS_FILENAME=${OPTARG};;
        t) _USE_TENANT_NAME=${OPTARG};;
        u) _USER_ADMIN_NAME=${OPTARG};;
        p) _USER_ADMIN_PWD=${OPTARG};;
        s) _USER_CPADMIN=1;;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_CMD}" ]]; then
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

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_rpa_require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "ERROR: 'jq' is required but not installed." >&2
    exit 1
  fi
}

# Check HTTP response for API errors (statusCode >= 400 or error fields)
_rpa_check_response() {
  local response="$1"
  local http_code
  http_code=$(echo "$response" | jq -r '.statusCode // empty' 2>/dev/null || true)
  if [[ -n "$http_code" ]] && [[ "$http_code" -ge 400 ]]; then
    log_error "ERROR CODE: API returned HTTP ${http_code}"
    _msg=$(echo "$response" | jq '.' 2>/dev/null || echo "$response" >&2)
    log_error "ERROR MESSAGE: ${_msg}"
    return 1
  fi
  # Also catch IBM RPA "error" wrapper
  local err_msg
  err_msg=$(echo "$response" | jq -r '.errorMessage // empty' 2>/dev/null || true)
  if [[ -n "$err_msg" ]]; then
    log_error "ERROR RPA MESSAGE: ${err_msg}"
    return 1
  fi
  return 0
}

# Assert that _RPA_ACCESS_TK is populated (call after loginAsRpaAdmin)
_rpa_require_token() {
  if [[ -z "${_RPA_ACCESS_TK:-}" ]]; then
    echo "ERROR: _RPA_ACCESS_TK is empty. Run loginAsRpaAdmin first." >&2
    return 1
  fi
}

# Assert that _ZEN_TK is populated (call after loginAsDeploymentAdmin)
_rpa_require_zen_token() {
  if [[ -z "${_ZEN_TK:-}" ]]; then
    echo "ERROR: _ZEN_TK is empty. Run loginAsDeploymentAdmin first." >&2
    return 1
  fi
}

#-----------------------------------------------------------------------------
getFieldFromJson () {
  _JSON="$1"
  _FIELD="$2"
  echo "${_JSON}" | jq .["${_FIELD}"] | sed 's/"//g'
}

#-------------------------------------------------------
loginAsDeploymentAdmin () {

  _ROUTE_NAME="platform-id-provider"

  # get pak admin username / password
  _USER_ADMIN_NAME=$(oc get secret platform-auth-idp-credentials -n ${CP4BA_INST_RPA_NAMESPACE} -o jsonpath='{.data.admin_username}' | base64 -d)
  _USER_ADMIN_PWD=$(oc get secret platform-auth-idp-credentials -n ${CP4BA_INST_RPA_NAMESPACE} -o jsonpath='{.data.admin_password}' | base64 -d)

  # echo "${_USER_ADMIN_NAME} / ${_USER_ADMIN_PWD}"

  _CONSOLE_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  _PAK_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} cpd -o jsonpath="{.spec.host}")

  # echo "$_PAK_HOST"
  # echo "$_CONSOLE_HOST"

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
              -d "grant_type=password&username=${_USER_ADMIN_NAME}&password=${_USER_ADMIN_PWD}&scope=openid" ${_CONSOLE_HOST}/idprovider/v1/auth/identitytoken)
  _USER_IAM_TK=$(echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_USER_IAM_TK}" ]]; then
    echo "Error identityToken: $_PAYLOAD"
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "username:${_USER_ADMIN_NAME}" -H "iam-token: $_USER_IAM_TK" $_PAK_HOST/v1/preauth/validateAuth)
  _USER_ACCESS_TK=$(echo "${_PAYLOAD}" | jq -r .accessToken 2>/dev/null)
  if [[ -z "${_USER_ACCESS_TK}" ]]; then
    echo "Error validateAuth: $_PAYLOAD"
    exit 1              
  fi

  _ZEN_TK=$(curl -sk "${_PAK_HOST}/v1/preauth/validateAuth" -H "username:${_USER_ADMIN_NAME}" -H "iam-token: ${_USER_IAM_TK}" | jq -r .accessToken)
  # echo "${_ZEN_TK}"

  _ACTION="usermgmt/v2/usermgmt/users"

  RESPONSE=$(curl -sk -H "Authorization: Bearer ${_ZEN_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' -X GET "${_PAK_HOST}/${_ACTION}?include_groups=true&offset=0&limit=25&search_str=${_USER_ADMIN_NAME}&include_users_count=false&includeAll=true")
  _ORIG_ROLES=$(echo ${RESPONSE} | jq .[].user_roles | sed 's/\[//g' | sed 's/\]//g' | sed 's/ //g' | sed '/^$/d')

  echo "Deployment admin user:${_USER_ADMIN_NAME}, roles: ${_ORIG_ROLES}"

}

#-------------------------------------------------------
loginAsRpaAdmin () {
  log_info "Logging in as '${_CLR_YELLOW}${_USER_ADMIN_NAME}${_CLR_GREEN}'"
  if [[ -z "${_USER_ADMIN_NAME}" ]] || [[ -z "${_USER_ADMIN_PWD}" ]]; then
    log_error "Missing admin user name or password"
    usage
    exit 1
  fi

  _ROUTE_NAME="platform-id-provider"

  _CONSOLE_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} ${_ROUTE_NAME} -o jsonpath="{.spec.host}")
  _PAK_HOST="https://"$(oc get route -n ${CP4BA_INST_RPA_NAMESPACE} cpd -o jsonpath="{.spec.host}")

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
              -d "grant_type=password&username="${_USER_ADMIN_NAME}"&password="${_USER_ADMIN_PWD}"&scope=openid" $_CONSOLE_HOST/idprovider/v1/auth/identitytoken)
  _USER_IAM_TK=$(echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_USER_IAM_TK}" ]]; then
    echo "Error identityToken: $_PAYLOAD"
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "username:${_USER_ADMIN_NAME}" -H "iam-token: $_USER_IAM_TK" $_PAK_HOST/v1/preauth/validateAuth)
  _USER_ACCESS_TK=$(echo "${_PAYLOAD}" | jq -r .accessToken 2>/dev/null)
  if [[ -z "${_USER_ACCESS_TK}" ]]; then
    echo "Error validateAuth: $_PAYLOAD"
    exit 1              
  fi

  _RPA_USER_INFO=$(curl -ks --cookie "ibm-private-cloud-session=$_USER_ACCESS_TK" $_PAK_HOST/rpa/api/zen-token-login)
  
  #echo $_RPA_USER_INFO | jq .
  
  _OIDC_TK=$(echo $_RPA_USER_INFO | jq -r .oidcAccessToken)
  
  _NUM_OF_TENANTS=$(echo $_RPA_USER_INFO | jq '.tenants | length')

  if [[ $_NUM_OF_TENANTS -eq 0 ]]; then
    log_error "No tenants found for user '${_USER_ADMIN_NAME}'."
    exit 1
  fi

  _TENANT_NAME=""
  if [[ ! -z "${_USE_TENANT_NAME}" ]]; then
    _SELECTED_TENANT=$(echo $_RPA_USER_INFO | jq '.tenants[] | select(.name=="'${_USE_TENANT_NAME}'")')
    _TENANT_ID=$(echo $_SELECTED_TENANT | jq .id | sed 's/"//g')
    _TENANT_NAME=$(echo $_SELECTED_TENANT | jq .name | sed 's/"//g')
    _TENANT_CODE=$(echo $_SELECTED_TENANT | jq .code | sed 's/"//g')
  fi
  if [[ -z "${_TENANT_NAME}" ]]; then
    # log_warning "Tenant '${_CLR_YELLOW}${_USE_TENANT_NAME}${_CLR_GREEN}' not administered by user '${_CLR_YELLOW}${_USER_ADMIN_NAME}${_CLR_GREEN}'."
    _TENANT_ID=$(echo $_RPA_USER_INFO | jq -r .tenants[0].id | sed 's/"//g')
    _TENANT_NAME=$(echo $_RPA_USER_INFO | jq -r .tenants[0].name | sed 's/"//g')
    _TENANT_CODE=$(echo $_RPA_USER_INFO | jq -r .tenants[0].code | sed 's/"//g')
  fi

  if [[ -z "${_OIDC_TK}" ]]; then
    log_error "Error OIDC Token not valid."
    exit 1              
  fi
  if [[ -z "${_TENANT_ID}" ]]; then
    log_error "Error Tenant ID not valid."
    exit 1              
  fi

  _PAYLOAD=$(curl -ks -H "Content-Type: application/x-www-form-urlencoded" -d grant_type=password --cookie "ibm-private-cloud-session=$_USER_ACCESS_TK" -H "tenantId:$_TENANT_ID" -H "oidc-access-token:$_OIDC_TK" $_PAK_HOST/rpa/api/v1.0/token)

  _RPA_ACCESS_TK=$( echo "${_PAYLOAD}" | jq -r .access_token 2>/dev/null)
  if [[ -z "${_RPA_ACCESS_TK}" ]]; then
    log_error "Error RPA access token not valid."
    exit 1              
  fi

  userDetails "${_USER_ADMIN_NAME}"
  # echo "user: ${_USER_DETAILS}"
  
  _USER_ID=$(echo $_USER_DETAILS | jq .results[0].id | sed 's/"//g')
  userRoles "${_USER_ID}"
  #echo "roles: ${_USER_ROLES}"

  _IS_PLATFORM_ADMIN=$(echo "${_USER_ROLES}" | jq .results[].name | grep "Administrator" | wc -l)

  if [[ ${_IS_PLATFORM_ADMIN} -lt 1 ]]; then
    log_warning "Warning user '${_USER_ADMIN_NAME}' is not a platform/tenant admin user."
    exit 1
  fi

}

#-------------------------------------------------------
rpaLoadRoles () {
  _url=$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")
  _RPA_ROLES_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${_url}/role?offset=0&limit=10&search=&asc=true&orderBy=name")

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

#------------------------------------
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

#-------------------------------------------------------
loadUsersRolesFromFile () {
  _FILE_USERS="$1"
  log_info "${_CLR_GREEN}Loading users from file '${_CLR_YELLOW}${_FILE_USERS}${_CLR_GREEN}'${_CLR_NC}"

  IFS=$'\n'
  LIST_OF_USERS=($(cat "${_FILE_USERS}" | sed 's/\r//g'))
  unset IFS
}

#-------------------------------------------------------
loadTenantsFromFile () {
  _FILE_TENANTS="$1"
  log_info "${_CLR_GREEN}Loading tenants from file '${_CLR_YELLOW}${_FILE_TENANTS}${_CLR_GREEN}'${_CLR_NC}"

  IFS=$'\n'
  LIST_OF_TENANTS=($(cat "${_FILE_TENANTS}" | sed 's/\r//g'))

}


#-------------------------------------------------------
onboardUsersAndConfigureRoles () {
  if [[ ! -z "${_USER_ROLES_FILENAME}" && ! -f "${_USER_ROLES_FILENAME}" ]]; then
    log_error "File users/roles not found."
    retrun 1
  fi
  
  loadUsersRolesFromFile "${_USER_ROLES_FILENAME}"
  
  if [[ ${#_ROLES_BY_ID[@]} -eq 0 ]]; then
    rpaLoadRoles
  fi

  for indexUserRoles in "${!LIST_OF_USERS[@]}"; do
    lineUserRoles="${LIST_OF_USERS[indexUserRoles]}"
    lineUserRoles=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${lineUserRoles})
    if [[ ! -z "${lineUserRoles}" ]]; then
      if [[ ! "$lineUserRoles" == "#"* ]]; then
        IFS=":" read -r userName roles <<< "${lineUserRoles}"
        IFS=',' read -r -a userRoles <<< "${roles}"
        userName=$(sed 's/ //g' <<<${userName})

        rpa_list_users_to_import 0 100 "${userName}"

        _USER_INFO=$(jq '.results[] | select(.name=="'${userName}'")' <<<${_RPA_RESULT_USERS})
        if [[ ! -z "${_USER_INFO}" ]]; then

          _USER_NAME=$(echo ${_USER_INFO} | jq .name | sed 's/"//g')
          _USER_DISTINGUISHED_NAME=$(echo ${_USER_INFO} | jq .distinguishedName | sed 's/"//g')
          _USER_EMAIL=$(echo ${_USER_INFO} | jq .email | sed 's/"//g')
          _USER_HAS_ACCESS=$(echo ${_USER_INFO} | jq .hasAccess | sed 's/"//g')

          _rolesBuffer=""
          _inserted=0
          for index in "${!userRoles[@]}"; do
            role="${userRoles[index]}"
            roleUntouched="${userRoles[index]}"
            role=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${role})
            getRoleIdByRoleName "${role}"
            roleIdx=$?
            if [[ $roleIdx -ge 0 && $roleIdx -ne 255 ]]; then
              roleId="${_ROLES_BY_ID[roleIdx]}"
              # echo "  role-> [$index] '${role}' / '${roleId}'"
              if [[ ! -z "${roleId}" ]]; then 
                if [[ $_inserted -gt 0 ]]; then
                  _rolesBuffer="${_rolesBuffer},"
                fi            
                _rolesBuffer="${_rolesBuffer}\"${roleId}\""
                _inserted=1
              else
                log_error "Role '${roleUntouched}' not found"
              fi
            else
              log_error "Role '${roleUntouched}' not found"
            fi
          done
          RESPONSE=""
          _strUR="${userRoles[@]}"
          _strUR=$(echo "$_strUR" | sed 's/  /, /g')
          if [[ "${_USER_HAS_ACCESS}" == "false" ]]; then
            log_info "Onboard and configure '${_CLR_YELLOW}${userName}${_CLR_GREEN}' with [${_CLR_YELLOW}${#userRoles[@]}${_CLR_GREEN}] roles [${_CLR_YELLOW}${_strUR}${_CLR_GREEN}]"
            rpa_add_user_to_tenant "${_USER_NAME}" "${_USER_EMAIL}" "${_rolesBuffer}"

          else
            log_info "Configure '${_CLR_YELLOW}${userName}${_CLR_GREEN}' with [${_CLR_YELLOW}${#userRoles[@]}${_CLR_GREEN}] roles [${_CLR_YELLOW}${_strUR}${_CLR_GREEN}]"
            _RECORD='{
              "roles": ['${_rolesBuffer}']
            }'
            userDetails "${_USER_NAME}"
            _USER_ID=$(echo $_USER_DETAILS | jq .results[0].id | sed 's/"//g')
            if [[ ! -z "${_USER_ID}" ]]; then
              rpa_change_user_roles "${_USER_ID}" "${_RECORD}"
            fi
          fi

        else
          log_warning "User '${_CLR_YELLOW}${userName}${_CLR_GREEN}' not in users domains, skip configuration."
        fi
      fi
    fi
  done
  unset IFS

}

#-------------------------------------------------------
removeUsers() {

  if [[ ! -z "${_USER_ROLES_FILENAME}" && ! -f "${_USER_ROLES_FILENAME}" ]]; then
    log_error "File users not found."
    retrun 1
  fi
  
  loadUsersRolesFromFile "${_USER_ROLES_FILENAME}"
  
  for indexUserRoles in "${!LIST_OF_USERS[@]}"; do
    lineUserRoles="${LIST_OF_USERS[indexUserRoles]}"
    lineUserRoles=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${lineUserRoles})
    if [[ ! -z "${lineUserRoles}" ]]; then
      if [[ ! "$lineUserRoles" == "#"* ]]; then
        IFS=":" read -r userName roles <<< "${lineUserRoles}"
        userName=$(sed 's/ //g' <<<${userName})
        if [[ "${userName}" != "${_USER_ADMIN_NAME}" ]]; then
          if [[ ! -z "${userName}" ]]; then
            rpa_remove_user_from_tenant "${userName}"
            log_info "User '${_CLR_YELLOW}${userName}${_CLR_GREEN}' removed from tenant '${_CLR_YELLOW}${_TENANT_NAME}' / '${_TENANT_CODE}${_CLR_GREEN}'"
          fi
        else
          log_warning "Skip user '${userName}', is tenant admin."
        fi
      fi
    fi
  done
  unset IFS

}

#-------------------------------------------------------
addTenants() {

  if [[ -z "${_TENANTS_FILENAME}" || ! -f "${_TENANTS_FILENAME}" ]]; then
    log_error "Tenants file not found."
    return 1
  fi
  
  loadTenantsFromFile "${_TENANTS_FILENAME}"

  for indexTenants in "${!LIST_OF_TENANTS[@]}"; do
    lineTenants="${LIST_OF_TENANTS[indexTenants]}"
    lineTenants=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${lineTenants})
    if [[ ! -z "${lineTenants}" ]]; then
      if [[ ! "$lineTenants" == "#"* ]]; then
        IFS="," read -r tenantName tenantAdmin tenantLocale <<< "${lineTenants}"
        tenantName=$(sed 's/ //g' <<<${tenantName})
        tenantAdmin=$(sed 's/ //g' <<<${tenantAdmin})
        tenantLocale=$(sed 's/ //g' <<<${tenantLocale})

        if [[ ! -z "${tenantName}" && ! -z "${tenantAdmin}" ]]; then
          rpa_list_users_to_import 0 100 "${tenantAdmin}"

          _USER_INFO=$(jq '.results[] | select(.name=="'${tenantAdmin}'")' <<<${_RPA_RESULT_USERS})
          if [[ ! -z "${_USER_INFO}" ]]; then
            tenantAdminEmail=$(echo ${_USER_INFO} | jq .email | sed 's/"//g')
            rpa_create_tenant "${tenantName}" "${tenantAdmin}" "${tenantAdminEmail}" "${tenantLocale}"
            if [[ $? -eq 0 ]]; then
              log_info "Added tenant '${_CLR_YELLOW}${tenantName}${_CLR_GREEN}' administered by '${_CLR_YELLOW}${tenantAdmin}${_CLR_GREEN}'"
            fi
          else
            log_error "Tenant admin '${tenantAdmin}' not in users domains, skip tenant configuration."
          fi
        else
          log_error "Tenant name '${tenantName}' or admin name '${tenantAdmin}' not valid"
        fi
      fi
    fi
  done
  unset IFS  

}

#-------------------------------------------------------
_removeTenant() {
  _removed=0
  tenantName="$1"
  if [[ ! -z "${tenantName}" ]]; then
    _TID=$(rpa_get_active_tenant_id_by_name "${tenantName}")
    if [[ ! -z "${_TID}" ]]; then
      rpa_suspend_tenant "${_TID}"
      rpa_delete_tenant "${_TID}"
      log_info "Removed tenant '${_CLR_YELLOW}${tenantName}${_CLR_GREEN}' '${_CLR_YELLOW}${_TID}${_CLR_GREEN}'"
      _removed=1
    else
      rpa_list_suspended_tenants
      _IDS=$(echo $_RPA_RESULT_SUSPENDED_TENANTS | jq '.results[]? | select(select(.name=="'${tenantName}'")) | .id ')
      IFS=$'\n'
      LIST_OF_TID=($(echo "${_IDS}" | sed 's/\r//g'))
      for index in "${!LIST_OF_TID[@]}"; do
        _tid=$(sed 's/"//g' <<<"${LIST_OF_TID[index]}")
        rpa_delete_tenant "${_tid}"
        log_info "Removed suspended tenant '${_CLR_YELLOW}${tenantName}${_CLR_GREEN}' '${_CLR_YELLOW}${_tid}${_CLR_GREEN}'"
        _removed=1
      done      
    fi
    if [[ $_removed -eq 0 ]]; then
      log_warning "Tenant name '${tenantName}' not found."
    fi
  else
    log_error "Tenant name '${tenantName}' not valid"
  fi
}

#-------------------------------------------------------
removeTenants() {

  if [[ ! -z "${_USE_TENANT_NAME}" ]]; then
    _removeTenant "${_USE_TENANT_NAME}"
  fi

  if [[ -z "${_TENANTS_FILENAME}" || ! -f "${_TENANTS_FILENAME}" ]]; then
    if [[ -z "${_USE_TENANT_NAME}" ]]; then
      log_error "Tenants file not found."
    fi
    return 1
  fi
  
  loadTenantsFromFile "${_TENANTS_FILENAME}"

  for indexTenants in "${!LIST_OF_TENANTS[@]}"; do
    lineTenants="${LIST_OF_TENANTS[indexTenants]}"
    lineTenants=$(sed 's/^[ \t]*//;s/[ \t]*$//' <<<${lineTenants})
    if [[ ! -z "${lineTenants}" ]]; then
      if [[ ! "$lineTenants" == "#"* ]]; then
        IFS="," read -r tenantName tenantAdmin tenantLocale <<< "${lineTenants}"
        tenantName=$(sed 's/ //g' <<<${tenantName})
        _removeTenant "${tenantName}"
      fi
    fi
  done
  unset IFS  
}

#-------------------------------------------------------
listTenants() {
  log_info "List of active tenants"
  rpa_list_active_tenants
  rpa_show_active_tenants

  log_info "List of suspended tenants"
  rpa_list_suspended_tenants
  rpa_show_suspended_tenants

}


#-------------------------------------------------------
userDetails () {
  _USER_NAME="$1"
  unset _USER_DETAILS
  _url=$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")
  _USER_DETAILS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${_url}/user?offset=0&limit=1000&search=${_USER_NAME}&deactivatedOnly=false")
}

#-------------------------------------------------------
userRoles () {
  _USER_ID="$1"
  _url=$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")
  _USER_ROLES=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${_url}/user/"${_USER_ID}"/roles?all=true")
}


#-------------------------------------------------------
rpaBotsList () {
  _url=$(_rpa_base_url "v2.0" "")
  _RPA_BOTS_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${_url}/workspace/${_WORKSPACE_ID}/bots")
}

#---------------------------------------------------------------------------
_rpa_base_url() {
  _VER="v2.0"
  if [[ ! -z "$1" ]]; then
    _VER="$1"
  fi
  _LOC=""
  if [[ ! -z "$2" ]]; then
    _LOC="/$2"
  fi
  echo "${_PAK_HOST}/rpa/api/${_VER}${_LOC}"
}

#-----------------------------------------------------------------------------
rpa_list_users_to_import() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  local search="${3:-}"
  
  _rpa_require_token || return 1

  local url
  url="$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/user/import?offset=${offset}&limit=${limit}&asc=true&orderBy=DisplayName&search=${search}"
  _RPA_RESULT_USERS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}")

  _rpa_check_response "$_RPA_RESULT_USERS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_users_to_import"
  return 1

}

#-----------------------------------------------------------------------------
rpa_list_tenant_users() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  local search="${3:-}"
  
  _rpa_require_token || return 1

  local url
  url="$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/user?offset=${offset}&limit=${limit}&asc=true&orderBy=name&include=ModifiedBy,Tenant&deactivatedOnly=false&search="
  _RPA_RESULT_TENANT_USERS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}")

  _rpa_check_response "$_RPA_RESULT_TENANT_USERS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_tenant_users"
  return 1

}


#-----------------------------------------------------------------------------
rpa_create_user() {
  local login="$1"
  local full_name="$2"
  local email="$3"
  local password="$4"
  local roles_json="${5:-[{\"name\":\"RpaOperator\"}]}"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg login  "$login" \
    --arg name   "$full_name" \
    --arg email  "$email" \
    --arg pass   "$password" \
    --argjson roles "$roles_json" \
    '{
      login:    $login,
      name:     $name,
      email:    $email,
      password: $pass,
      roles:    $roles
    }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/user" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_USER=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_USER=$(echo "$response" | jq '{ id: .id, login: .login, email: .email, roles: [.roles[]? | .name] }')
    return 0
  fi
  log_error "rpa_create_user"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_roles() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_ROLES=$(curl -sk -X GET \
    "$(_rpa_base_url)/role?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_ROLES"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_roles"
  return 1

}

#-----------------------------------------------------------------------------
rpa_show_roles() {
  
  echo "$_RPA_RESULT_ROLES" | jq '{
    total:   .total,
    results: [.results[]? | { id: .id, name: .name, description: .description }]
  }'
}

#-----------------------------------------------------------------------------
rpa_list_teams() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  _RPA_RESULT_TEAMS=$(curl -sk -X GET \
    "$(_rpa_base_url)/team?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_TEAMS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_teams"
  return 1

}

#-----------------------------------------------------------------------------
rpa_show_teams() {
  
  echo "$_RPA_RESULT_TEAMS" | jq '{
    total:   .total,
    results: [.results[]? | { id: .id, name: .name, description: .description }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_team() {
  local team_name="$1"
  local description="${2:-}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  local payload
  payload=$(jq -n \
    --arg name "$team_name" \
    --arg desc "$description" \
    '{ name: $name, description: $desc }')

  _RPA_RESULT_TEAMS=$(curl -sk -X POST "$(_rpa_base_url)/team" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$_RPA_RESULT_TEAMS"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_TEAM=$(echo "$_RPA_RESULT_TEAMS" | jq '{ id: .id, name: .name, description: .description }')
    return 0
  fi
  log_error "rpa_create_team"
  return 1  
}

#-----------------------------------------------------------------------------
rpa_add_user_to_team() {
  local team_id="$1"
  local user_id="$2"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  local payload
  payload=$(jq -n --arg uid "$user_id" '{ userId: $uid }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/team/${team_id}/user" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_add_user_to_team"
  return 1
}

#-----------------------------------------------------------------------------
rpa_create_role() {
  local role_name="$1"
  local description="${2:-}"
  local permissions_json="${3:-[]}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – custom role creation endpoint path not confirmed in public docs

  local payload
  payload=$(jq -n \
    --arg name "$role_name" \
    --arg desc "$description" \
    --argjson perms "$permissions_json" \
    '{ name: $name, description: $desc, permissions: $perms }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/role" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_create_role"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_active_tenants() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_TENANTS=$(curl -sk -X GET \
    "$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/tenant?offset=${offset}&limit=${limit}&asc=true&orderBy=name&suspendedOnly=false" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_TENANTS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_active_tenants"
  return 1

}

#-----------------------------------------------------------------------------
rpa_list_suspended_tenants() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_SUSPENDED_TENANTS=$(curl -sk -X GET \
    "$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/tenant?offset=${offset}&limit=${limit}&asc=true&orderBy=name&suspendedOnly=true" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_SUSPENDED_TENANTS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_suspended_tenants"
  return 1

}

#-----------------------------------------------------------------------------
rpa_get_active_tenant_id_by_name() {
  rpa_list_active_tenants
  echo ${_RPA_RESULT_TENANTS} | jq '.results[] | select(.name=="'$1'")' | jq .id | sed 's/"//g'
}

#-----------------------------------------------------------------------------
rpa_get_suspended_tenant_id_by_name() {
  rpa_list_suspended_tenants
  echo ${_RPA_RESULT_SUSPENDED_TENANTS} | jq '.results[] | select(.name=="'$1'")' | jq .id | sed 's/"//g'
}


#-----------------------------------------------------------------------------
rpa_add_user_to_tenant() {
  local userName="${1:-}"
  local userEmail="${2:-}"
  local _rolesBuffer="${3}"

  _rpa_require_token || return 1

  if [[ -z "${userName}" || -z "${userEmail}" || -z "${_rolesBuffer}" ]]; then
    log_warning "Cannot add user '${userName}' to tenant"
    return 1
  fi

  local payload='{
    "roles":['${_rolesBuffer}'],
    "teams":[],
    "users":[
      {"name":"'${userName}'","email":"'${userEmail}'","distinguishedName":"'${userName}'"}
    ]
  }'

  local url="$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/user/import"
  local response
  response=$(curl -sk -X POST "${url}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_add_user_to_tenant"
  return 1

}

#-----------------------------------------------------------------------------
rpa_change_user_roles() {
  local userId="${1}"
  local record="${2}"

  _url=$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")
  response=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
            -X PATCH -d "${record}" "${_url}/user/$userId/roles")
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_change_user_roles"
  return 1

} 

#-----------------------------------------------------------------------------
rpa_remove_user_from_tenant() {
  local userName="${1:-}"

  if [[ ! -z "${userName}" ]]; then
    _rpa_require_token || return 1

    userDetails "${userName}"
    _userId=$(echo $_USER_DETAILS | jq .results[0].id | sed 's/"//g')

    if [[ ! -z "${_userId}" ]]; then

      local url="$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/user/${_userId}/deactivate"

      local response
      response=$(curl -sk -X POST "${url}" \
        -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$payload")

      _rpa_check_response "$response"
      if [[ $? -eq 0 ]]; then
        return 0
      fi
      log_error "rpa_remove_user_from_tenant"
      return 1
    else
      log_error "User '${userName}' not found."
    fi
  else
    log_error "Username is empty."
  fi
  return 1
}

#-----------------------------------------------------------------------------
rpa_get_account_info() {
  local url="$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/account/install-key"
  _RPA_ACCOUNT_INFO=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}" | base64 -d)

  _rpa_check_response "$_RPA_ACCOUNT_INFO"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_get_account_info"
  return 1

}

#-----------------------------------------------------------------------------
rpa_show_active_tenants() {
  
  echo "$_RPA_RESULT_TENANTS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:               .id,
      name:             .name,
      code:             .code,
      isApproved:	      .isApproved,
      isDeactivated:    .isDeactivated,
      isSuperTenant:    .isSuperTenant,
      ownerId:          .ownerId
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_show_suspended_tenants() {
  
  echo "$_RPA_RESULT_SUSPENDED_TENANTS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:                 .id,
      name:               .name,
      code:               .code,
      isApproved:	        .isApproved,
      isDeactivated:      .isDeactivated,
      deactivationDate:   .deactivationDate,
      removalRequestDate: .removalRequestDate,
      isSuperTenant:      .isSuperTenant,
      ownerId:            .ownerId
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_tenant() {
  local name="$1"
  local admin_name="$2"
  local admin_email="$3"
  local tenant_locale="$4"
  _RPA_RESULT_NEW_TENANT=""
  
  _rpa_require_token || return 1

  local payload
  payload='{
      "name":       "'$name'",
      "userName":   "'$admin_name'",
      "userEmail":  "'$admin_email'",
      "lcid":       '$tenant_locale'
    }'

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/tenant" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_RESULT_NEW_TENANT=$(echo "$response" | jq '{ id: .id}')
    return 0
  fi
  return 1
}

#-----------------------------------------------------------------------------
rpa_suspend_tenant() {
  local tenant_id="$1"
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X PATCH "$(_rpa_base_url)/tenant/${tenant_id}/suspend" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_suspend_tenant"
  return 1
}

#-----------------------------------------------------------------------------
rpa_resume_tenant() {
  local tenant_id="$1"
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X PATCH "$(_rpa_base_url)/tenant/${tenant_id}/resume" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_resume_tenant"
  return 1
}

#-----------------------------------------------------------------------------
rpa_delete_tenant() {
  local tenant_id="$1"
  
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X DELETE "$(_rpa_base_url "v1.0" "${_RPA_LOCALE}")/tenant/${tenant_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_delete_tenant"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_credentials() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_CREDENTIALS=$(curl -sk -X GET \
    "$(_rpa_base_url)/credential?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_CREDENTIALS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_credentials"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_credentials() {
  
  echo "$_RPA_RESULT_CREDENTIALS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      type:        .type
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_credential() {
  local name="$1"
  local description="$2"
  local type="${3:-UserPassword}"
  local login="$4"
  local password="$5"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg name  "$name" \
    --arg desc  "$description" \
    --arg type  "$type" \
    --arg login "$login" \
    --arg pass  "$password" \
    '{
      name:        $name,
      description: $desc,
      type:        $type,
      login:       $login,
      password:    $pass
    }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/credential" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_CREDENTIAL=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_CREDENTIAL=$(echo "$response" | jq '{ id: .id, name: .name, type: .type }')
    return 0
  fi
  log_error "rpa_create_credential"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_credential_pools() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  _RPA_RESULT_CREDENTIAL_POOLS=$(curl -sk -X GET \
    "$(_rpa_base_url)/credential/pool?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_CREDENTIAL_POOLS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_credential_pools"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_credential_pools() {
  
  echo "$_RPA_RESULT_CREDENTIAL_POOLS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      credentials: [.credentials[]? | { id: .id, name: .name }]
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_credential_pool() {
  local name="$1"
  local description="$2"
  local credential_ids_json="${3:-[]}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  local payload
  payload=$(jq -n \
    --arg  name "$name" \
    --arg  desc "$description" \
    --argjson ids "$credential_ids_json" \
    '{
      name:          $name,
      description:   $desc,
      credentialIds: $ids
    }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/credential/pool" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_CREDS_POOL=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_CREDS_POOL=$(echo "$response" | jq '{ id: .id, name: .name, description: .description }')
    return 0
  fi
  log_error "rpa_create_credential_pool"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_computers() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_COMPUTERS=$(curl -sk -X GET \
    "$(_rpa_base_url)/computer?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_COMPUTERS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_computers"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_computers() {
  
  echo "$_RPA_RESULT_COMPUTERS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:              .id,
      name:            .name,
      status:          .status,
      computerGroupId: .computerGroupId,
      multiSession:    .multiSession
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_list_computer_groups() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_COMPUTER_GROUPS=$(curl -sk -X GET \
    "$(_rpa_base_url)/computer/group?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_COMPUTER_GROUPS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_computer_groups"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_computer_groups() {
  
  echo "$_RPA_RESULT_COMPUTER_GROUPS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_computer_group() {
  local name="$1"
  local description="${2:-}"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg name "$name" \
    --arg desc "$description" \
    '{ name: $name, description: $desc }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/computer/group" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_COMPUTER_GROUP=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_COMPUTER_GROUP=$(echo "$response" | jq '{ id: .id, name: .name, description: .description }')
    return 0
  fi
  log_error "rpa_create_computer_group"
  return 1
  
}

#-----------------------------------------------------------------------------
rpa_update_computer() {
  local computer_id="$1"
  local computer_group_id="$2"
  local multi_session="${3:-false}"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg  gid "$computer_group_id" \
    --argjson ms "$multi_session" \
    '{
      computerGroupId: $gid,
      multiSession:    $ms
    }')

  local response
  response=$(curl -sk -X PUT "$(_rpa_base_url)/computer/${computer_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_update_computer"
  return 1
}

#-----------------------------------------------------------------------------
rpa_list_projects() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  _RPA_RESULT_PROJECTS=$(curl -sk -X GET \
    "$(_rpa_base_url)/project?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_PROJECTS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_projects"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_projects() {
  
  echo "$_RPA_RESULT_PROJECTS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      teamId:      .teamId
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_project() {
  local name="$1"
  local description="$2"
  local team_id="${3:-}"
  
  _rpa_require_token || return 1

  local payload
  if [[ -n "$team_id" ]]; then
    payload=$(jq -n \
      --arg name "$name" \
      --arg desc "$description" \
      --arg tid  "$team_id" \
      '{ name: $name, description: $desc, teamId: $tid }')
  else
    payload=$(jq -n \
      --arg name "$name" \
      --arg desc "$description" \
      '{ name: $name, description: $desc }')
  fi

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/project" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_PROJECT=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_PROJECT=$(echo "$response" | jq '{ id: .id, name: .name, description: .description, teamId: .teamId }')
    return 0
  fi
  log_error "rpa_create_project"
  return 1

}

#-----------------------------------------------------------------------------
rpa_list_bots() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  if [[ -z "${_WORKSPACE_ID:-}" ]]; then
    return 1
  fi
  _url=$(_rpa_base_url "v2.0" "")
  _RPA_RESULT_BOTS=$(curl -sk -X GET \
    "${_url}/workspace/${_WORKSPACE_ID}/bots?offset=${offset}&limit=${limit}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$_RPA_RESULT_BOTS"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_list_bots"
  return 1
}

#-----------------------------------------------------------------------------
rpa_show_bots() {
  
  echo "$_RPA_RESULT_BOTS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:              .id,
      name:            .name,
      description:     .description,
      scriptId:        .scriptId,
      scriptVersion:   .scriptVersion,
      computerGroupId: .computerGroupId,
      status:          .status
    }]
  }'
}

#-----------------------------------------------------------------------------
rpa_create_bot() {
  local name="$1"
  local description="$2"
  local script_id="$3"
  local script_version="${4:-1}"
  local computer_group_id="$5"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg name   "$name" \
    --arg desc   "$description" \
    --arg sid    "$script_id" \
    --arg sver   "$script_version" \
    --arg cgid   "$computer_group_id" \
    '{
      name:            $name,
      description:     $desc,
      scriptId:        $sid,
      scriptVersion:   $sver,
      computerGroupId: $cgid
    }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base_url)/bot" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _RPA_NEW_BOT=""
  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    _RPA_NEW_BOT=$(echo "$response" | jq '{
      id:              .id,
      name:            .name,
      description:     .description,
      scriptId:        .scriptId,
      scriptVersion:   .scriptVersion,
      computerGroupId: .computerGroupId
    }')
    return 0
  fi
  log_error "rpa_create_bot"
  return 1

}

#-----------------------------------------------------------------------------
rpa_update_bot() {
  local bot_id="$1"
  local description="$2"
  local script_id="$3"
  local script_version="${4:-1}"
  local computer_group_id="$5"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg desc "$description" \
    --arg sid  "$script_id" \
    --arg sver "$script_version" \
    --arg cgid "$computer_group_id" \
    '{
      description:     $desc,
      scriptId:        $sid,
      scriptVersion:   $sver,
      computerGroupId: $cgid
    }')

  local response
  response=$(curl -sk -X PUT "$(_rpa_base_url)/bot/${bot_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  if [[ $? -eq 0 ]]; then
    return 0
  fi
  log_error "rpa_update_bot"
  return 1
}


#===================================================================
# TESTS
#===================================================================


testTenantCreate () {
  loginAsRpaAdmin

  _name="TENANT-A"
  _admin="rpatenantadmin1" 
  _adminmail="rpatenantadmin1@vuxrpaprod.net"

  rpa_list_active_tenants
  rpa_show_active_tenants
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}" "1033"
  log_info "_RPA_RESULT_NEW_TENANT: $_RPA_RESULT_NEW_TENANT"
  rpa_list_active_tenants
  rpa_show_active_tenants

}

testTenantCreateDelete () {
  loginAsRpaAdmin

  _name="TENANT1"
  _admin="rpatenantadmin1" 
  _adminmail="rpatenantadmin1@vuxrpaprod.net"

  rpa_list_active_tenants
  rpa_show_active_tenants
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}" "1033"
  log_info "_RPA_RESULT_NEW_TENANT: $_RPA_RESULT_NEW_TENANT"
  rpa_list_active_tenants
  rpa_show_active_tenants

  sleep 10
  _TID=$(rpa_get_active_tenant_id_by_name "${_name}")
  if [[ ! -z "${_TID}" ]]; then
    rpa_suspend_tenant "${_TID}"
    rpa_delete_tenant "${_TID}"
  else
    _TID=$(rpa_get_suspended_tenant_id_by_name "${_name}")
    if [[ ! -z "${_TID}" ]]; then
      rpa_delete_tenant "${_TID}"
    else
      log_error "Tenant '${_name}' not found"
    fi  
  fi

  sleep 1
  rpa_list_active_tenants
  rpa_show_active_tenants

}

testTenantCreateSuspend () {
  loginAsRpaAdmin

  _name="TENANT1"
  _admin="rpatenantadmin1" 
  _adminmail="rpatenantadmin1@vuxrpaprod.net"

  rpa_list_active_tenants
  rpa_show_active_tenants
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}" "1033"
  log_info "_RPA_RESULT_NEW_TENANT: $_RPA_RESULT_NEW_TENANT"
  rpa_list_active_tenants
  rpa_show_active_tenants

  sleep 10
  _TID=$(rpa_get_active_tenant_id_by_name "${_name}")
  if [[ ! -z "${_TID}" ]]; then
    rpa_suspend_tenant "${_TID}"
    sleep 1
    rpa_list_suspended_tenants
    rpa_show_suspended_tenants
  fi

}

testTenantDelete () {
  loginAsRpaAdmin

  _name="TENANT1"

  _TID=$(rpa_get_suspended_tenant_id_by_name "${_name}")
  if [[ ! -z "${_TID}" ]]; then
    rpa_delete_tenant "${_TID}"
    sleep 1
    rpa_list_suspended_tenants
    rpa_show_suspended_tenants
  fi

}

testLoginAsTenantAdminAndCreateUsers() {
  _USER_ADMIN_NAME="rpatenantadmin1" 
  #_USER_ADMIN_NAME="rpaadmin" 
  _USER_ADMIN_PWD="dem0s"
  # ="rpatenantadmin1@vuxrpaprod.net"
  loginAsRpaAdmin

  log_info "User:"
  echo $_USER_DETAILS | jq .

  rpa_get_account_info
  echo "${_RPA_ACCOUNT_INFO}" | jq .  

  rpa_list_active_tenants
  rpa_show_active_tenants

  rpa_list_tenant_users
  echo "${_RPA_RESULT_TENANT_USERS}" | jq .

  # rpa_list_users_to_import 0 100 "rpa"
  # echo "${_RPA_RESULT_USERS}" | jq .

  onboardUsersAndConfigureRoles

}


testLoginAsTenantAdminAndRemoveUsers() {
  _USER_ADMIN_NAME="rpatenantadmin1" 
  _USER_ADMIN_PWD="dem0s"
  loginAsRpaAdmin
  rpa_remove_user_from_tenant "rpauser11"
}

checkRequiredTools(){
  _rpa_require_jq
}


#=====================================
# Test Tenant
#=====================================
# testTenantCreate
# testTenantCreateDelete
# testTenantCreateSuspend
# testTenantDelete

#=====================================
# Test User
#=====================================
# testLoginAsTenantAdminAndCreateUsers
# testLoginAsTenantAdminAndRemoveUsers

# echo "Work in progress, do not use this script"


#=====================================
# Samples section
#=====================================

# export CP4BA_INST_NAMESPACE="cp4ba-rpa-34-managed-1"
# export CP4BA_LOGGING_ENABLED="true"

#-------------------------------------------
# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addtenants -f ../rpa-day2/tenants

# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k removetenants -f ../rpa-day2/tenants

# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k removetenants -t test1


#-------------------------------------------
# Use -t to telect a specific tenant, otherwise the tool automatically select the first tenant in list of managed by the user

# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-1

# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2 -t TENANT-A

# ./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3 -t TENANT-B

# ./cp4ba-rpa-day2-automations.sh -u rpatenantadmin1 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2

# ./cp4ba-rpa-day2-automations.sh -u rpatenantadmin1 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2 -t tenant-dev

# ./cp4ba-rpa-day2-automations.sh -u rpatenantadmin2 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3

# ./cp4ba-rpa-day2-automations.sh -u rpatenantadmin2 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3 -t tenant-prod

#-------------------------------------------



log_info "======================================================="
log_info "RPA Day2 tools"
log_info "======================================================="

loginAsRpaAdmin
log_info "User '${_CLR_YELLOW}${_USER_ADMIN_NAME}${_CLR_GREEN}', namespace '${_CLR_YELLOW}${CP4BA_INST_RPA_NAMESPACE}${_CLR_GREEN}'"
log_info "Logged to tenant name '${_CLR_YELLOW}${_TENANT_NAME}${_CLR_GREEN}', code '${_CLR_YELLOW}${_TENANT_CODE}${_CLR_GREEN}', id '${_CLR_YELLOW}${_TENANT_ID}${_CLR_GREEN}'"

case "${_CMD}" in

  "addusers")
    onboardUsersAndConfigureRoles
    ;;

  "removeusers")
    removeUsers
    ;;

  "addtenants")
    addTenants
    ;;

  "removetenants")
    removeTenants
    ;;

  "listtenants")
    listTenants
    ;;

  *)
    log_error "Command '${_CMD}' not found"
    usage
    exit 1
    ;;

esac




