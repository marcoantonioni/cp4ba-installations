#!/usr/bin/env bash

__DEBUG_MODE=${__DEBUG_MODE:-0}

_INST_TMP_FOLDER="${_INST_TMP_FOLDER:-/tmp}"

_USER_ADMIN_NAME="${_USER_ADMIN_NAME:-}"
_USER_ADMIN_PWD="${_USER_ADMIN_PWD:-}"

_USER_IAM_TK=""
_USER_ACCESS_TK=""
_OIDC_TK=""
_TENANT_ID=""
_RPA_ACCESS_TK=""
_ZEN_TK=""
CONSOLE_HOST=""
PAK_HOST=""

CP4BA_INST_RPA_NAMESPACE="${CP4BA_INST_RPA_NAMESPACE:-cp4ba}"


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

# MODIFICATION 2026-10-22: Added logging helper functions (log_info,
#   log_warning, log_error) referenced by loginAsRpaAdmin but previously
#   undefined. Uses ANSI color codes for readability; safe to override.
log_info() {
  echo -e "\033[0;32m[INFO]\033[0m  $*"
}

log_warning() {
  echo -e "\033[0;33m[WARN]\033[0m  $*" >&2
}

log_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $*" >&2
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

  [[ $__DEBUG_MODE -eq 1 ]] && echo "User info------------------------------------"
  [[ $__DEBUG_MODE -eq 1 ]] && echo $_RPA_USER_INFO | jq .
  [[ $__DEBUG_MODE -eq 1 ]] && echo "---------------------------------------------"
  
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
  # &search=
  _RESULT_LIMIT=100

  #_RPA_USERS_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user/import?offset=0&limit=${_RESULT_LIMIT}&asc=true&orderBy=DisplayName")
echo "rpaLoadUsers"
  #curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user/import?offset=0&limit=100&asc=true&orderBy=DisplayName"

curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "https://cpd-cp4ba-rpa-34-managed-1.apps.itz-rnvsfs.infra01-lb.fra02.techzone.ibm.com/rpa/api/v1.0/en-US/user/import?offset=0&limit=100&asc=true&orderBy=DisplayName"

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

_USER_DETAILS="{}"
userDetails () {
  _USER_NAME="$1"
  unset _USER_DETAILS
  _USER_DETAILS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user?offset=0&limit=1000&search=${_USER_NAME}&deactivatedOnly=false")
}

_USER_ROLES="{}"
userRoles () {
  _USER_ID="$1"
  _USER_ROLES=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -H 'accept: application/json' -H 'Content-Type: application/json' \
      -X GET "${PAK_HOST}/rpa/api/v1.0/en-US/user/"${_USER_ID}"/roles?all=true")

  [[ $__DEBUG_MODE -eq 1 ]] && echo "USER ROLES ----------------------------------"
  [[ $__DEBUG_MODE -eq 1 ]] && echo "$_USER_ROLES" | jq .
  [[ $__DEBUG_MODE -eq 1 ]] && echo "---------------------------------------------"
}


_RPA_BOTS_LIST="{}"
rpaBotsList () {
  _RPA_BOTS_LIST=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${PAK_HOST}/rpa/api/v2.0/workspace/${_WORKSPACE_ID}/bots")
}

# =============================================================================
# IBM RPA 30.0.x – Day-2 Automation Functions for CP4BA (Container / Zen)
# Reference: https://www.ibm.com/docs/en/rpa/30.0.x?topic=automation-rpa-apis
#
# AUTHENTICATION MODEL
#   This script reuses the CP4BA Zen authentication chain defined in
#   ./knowledge/commons.sh:
#     1. loginAsDeploymentAdmin  → _ZEN_TK   (platform/deployment-admin ops)
#     2. loginAsRpaAdmin         → _RPA_ACCESS_TK + _TENANT_ID  (RPA tenant ops)
#
#   All functions in this file consume _RPA_ACCESS_TK, _ZEN_TK, PAK_HOST, and
#   _TENANT_ID from commons.sh.  Call one of the login functions BEFORE any
#   Day-2 function.
#
# USAGE
#   export CP4BA_INST_RPA_NAMESPACE="cp4ba"        # OpenShift namespace
#   export _USER_ADMIN_NAME="rpaAdmin"
#   export _USER_ADMIN_PWD="Passw0rd!"
#   source ./knowledge/commons.sh
#   source ./output/cp4ba-rpa-day2-automations.sh
#
#   loginAsRpaAdmin           # populate _RPA_ACCESS_TK, _TENANT_ID, PAK_HOST
#   rpa_list_users            # call any Day-2 function
#
# GLOBAL RESULT VARIABLES (each function stores its JSON response here):
#   RPA_RESULT_USERS          RPA_RESULT_ROLES        RPA_RESULT_TEAMS
#   RPA_RESULT_TENANTS        RPA_RESULT_CREDENTIALS  RPA_RESULT_CREDENTIAL_POOLS
#   RPA_RESULT_COMPUTERS      RPA_RESULT_COMPUTER_GROUPS
#   RPA_RESULT_PROJECTS       RPA_RESULT_BOTS
#
# NOTE ON LOCALE PREFIX
#   IBM RPA 30.0.x REST paths use a locale segment:
#     /rpa/api/v1.0/en-US/<resource>
#   The default locale is "en-US"; override via RPA_LOCALE if needed.
# =============================================================================

# ---------------------------------------------------------------------------
# 0.  CONFIGURATION
# ---------------------------------------------------------------------------

# Convenience shorthand: base URL for all RPA REST calls (built from PAK_HOST
# which is set by loginAsDeploymentAdmin / loginAsRpaAdmin in commons.sh).
# Evaluated at call time via the helper _rpa_base so PAK_HOST is never empty.
_rpa_base() {
  _VER="v2.0"
  if [[ ! -z "$1" ]]; then
    _VER="$1"
  fi
  _LOC=""
  if [[ ! -z "$2" ]]; then
    _LOC="/$2"
  fi
  echo "${PAK_HOST}/rpa/api/${_VER}${_LOC}"
}

# ---------------------------------------------------------------------------
# Global result variables (populated by each API function)
# ---------------------------------------------------------------------------
RPA_RESULT_USERS=""
RPA_RESULT_ROLES=""
RPA_RESULT_TEAMS=""
RPA_RESULT_TENANTS=""
RPA_RESULT_SUSPENDED_TENANTS=""
RPA_RESULT_NEW_TENANT=""
RPA_RESULT_CREDENTIALS=""
RPA_RESULT_CREDENTIAL_POOLS=""
RPA_RESULT_COMPUTERS=""
RPA_RESULT_COMPUTER_GROUPS=""
RPA_RESULT_PROJECTS=""
RPA_RESULT_BOTS=""

RPA_LOCALE="${RPA_LOCALE:-en-US}"
RPA_ACCOUNT_INFO=""

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_rpa_require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "ERROR: 'jq' is required but not installed." >&2
    return 1
  fi
}

# Check HTTP response for API errors (statusCode >= 400 or error fields)
_rpa_check_response() {
  local response="$1"
  local http_code
  http_code=$(echo "$response" | jq -r '.statusCode // empty' 2>/dev/null || true)
  if [[ -n "$http_code" ]] && [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: API returned HTTP ${http_code}" >&2
    echo "$response" | jq '.' 2>/dev/null || echo "$response" >&2
    return 1
  fi
  # Also catch IBM RPA "error" wrapper
  local err_msg
  err_msg=$(echo "$response" | jq -r '.errorMessage // empty' 2>/dev/null || true)
  if [[ -n "$err_msg" ]]; then
    echo "API message: ${err_msg}" >&2
  fi

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

# =============================================================================
# SECTION 1 – ADMINISTER ACCESS
# =============================================================================
# References:
#   GET    /rpa/api/v1.0/en-US/user                    – list users
#   POST   /rpa/api/v1.0/en-US/user                    – create user
#   GET    /rpa/api/v1.0/en-US/role                    – list roles
#   POST   /rpa/api/v1.0/en-US/role                    – create role  # NOT SECURE CODE
#   GET    /rpa/api/v1.0/en-US/team                    – list teams   # NOT SECURE CODE
#   POST   /rpa/api/v1.0/en-US/team                    – create team  # NOT SECURE CODE
#   POST   /rpa/api/v1.0/en-US/team/{teamId}/user      – add user to team # NOT SECURE CODE
# =============================================================================

# -----------------------------------------------------------------------------
rpa_list_users_to_import() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  local search="${3:-}"
  
  _rpa_require_token || return 1

  local url
  url="$(_rpa_base "v1.0" "${RPA_LOCALE}")/user/import?offset=${offset}&limit=${limit}&asc=true&orderBy=DisplayName&search=${search}"
  RPA_RESULT_USERS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}")

  _rpa_check_response "$RPA_RESULT_USERS"  
}

rpa_list_tenant_users() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  local search="${3:-}"
  
  _rpa_require_token || return 1

  local url
  url="$(_rpa_base "v1.0" "${RPA_LOCALE}")/user?offset=${offset}&limit=${limit}&asc=true&orderBy=name&include=ModifiedBy,Tenant&deactivatedOnly=false&search="
  RPA_RESULT_TENANT_USERS=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}")

  _rpa_check_response "$RPA_RESULT_TENANT_USERS"
}


# -----------------------------------------------------------------------------
# 1.2  CREATE USER WITH ROLES
# POST /rpa/api/v1.0/en-US/user
#
# Payload:
# {
#   "login":      "john.doe",
#   "name":       "John Doe",
#   "email":      "john.doe@example.com",
#   "password":   "Passw0rd!",
#   "roles":      [{ "name": "RpaOperator" }]
# }
# Response:
# {
#   "id": "...",
#   "login": "john.doe",
#   "name": "John Doe",
#   "email": "john.doe@example.com",
#   "enabled": true,
#   "roles": [{ "id": "...", "name": "RpaOperator" }]
# }
#
# Parameters:
#   $1  login         – user login name
#   $2  full_name     – display name
#   $3  email         – e-mail address
#   $4  password      – initial password
#   $5  roles_json    – JSON array of role objects, e.g. '[{"name":"RpaOperator"}]'
#                       Valid role names: RpaPlatformAdministrator,
#                       RpaTenantAdministrator, RpaOperator, RpaDeveloper,
#                       RpaBusinessAnalyst, RpaAuditor
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/user" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, login: .login, email: .email, roles: [.roles[]? | .name] }'
}

# -----------------------------------------------------------------------------
# 1.3  LIST ROLES
# GET /rpa/api/v1.0/en-US/role?offset=0&limit=50
#
# Response:
# {
#   "total": 6,
#   "results": [
#     { "id": "...", "name": "RpaOperator", "description": "..." }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_roles() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  RPA_RESULT_ROLES=$(curl -sk -X GET \
    "$(_rpa_base)/role?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_ROLES"
  echo "Roles retrieved. Use rpa_show_roles to inspect."
}

# Utility: display roles JSON structure
rpa_show_roles() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_ROLES" | jq '{
    total:   .total,
    results: [.results[]? | { id: .id, name: .name, description: .description }]
  }'
}

# -----------------------------------------------------------------------------
# 1.4  LIST TEAMS
# GET /rpa/api/v1.0/en-US/team?offset=0&limit=20
# NOT SECURE CODE – team endpoint path inferred; verify against your RPA version
#
# Response:
# {
#   "total": 2,
#   "results": [
#     { "id": "...", "name": "AutomationTeam", "description": "..." }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_teams() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  RPA_RESULT_TEAMS=$(curl -sk -X GET \
    "$(_rpa_base)/team?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_TEAMS"
  echo "Teams retrieved. Use rpa_show_teams to inspect."
}

# Utility: display teams JSON structure
rpa_show_teams() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_TEAMS" | jq '{
    total:   .total,
    results: [.results[]? | { id: .id, name: .name, description: .description }]
  }'
}

# -----------------------------------------------------------------------------
# 1.5  CREATE TEAM
# POST /rpa/api/v1.0/en-US/team
# NOT SECURE CODE – team endpoint path inferred; verify against your RPA version
#
# Payload:
# {
#   "name":        "AutomationTeam",
#   "description": "Team for RPA automations"
# }
# Response:
# { "id": "...", "name": "AutomationTeam", "description": "..." }
#
# Parameters:
#   $1  team_name     – team name
#   $2  description   – optional description
# -----------------------------------------------------------------------------
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

  local response
  response=$(curl -sk -X POST "$(_rpa_base)/team" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  RPA_RESULT_TEAMS="$response"
  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, description: .description }'
}

# -----------------------------------------------------------------------------
# 1.6  ADD USER TO TEAM
# POST /rpa/api/v1.0/en-US/team/{teamId}/user
# NOT SECURE CODE – endpoint path inferred; verify against your RPA version
#
# Payload:
# { "userId": "<userId>" }
#
# Parameters:
#   $1  team_id   – team UUID
#   $2  user_id   – user UUID
# -----------------------------------------------------------------------------
rpa_add_user_to_team() {
  local team_id="$1"
  local user_id="$2"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  local payload
  payload=$(jq -n --arg uid "$user_id" '{ userId: $uid }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base)/team/${team_id}/user" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "User ${user_id} added to team ${team_id}."
}

# -----------------------------------------------------------------------------
# 1.7  CREATE ROLE  (custom role)
# POST /rpa/api/v1.0/en-US/role
# NOT SECURE CODE – custom role creation endpoint inferred; verify in docs
#
# Payload:
# {
#   "name":        "MyCustomRole",
#   "description": "Custom automation role",
#   "permissions": ["..."]
# }
#
# Parameters:
#   $1  role_name       – role name
#   $2  description     – optional description
#   $3  permissions_json – JSON array of permission strings (optional, default [])
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/role" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, description: .description }'
}

# =============================================================================
# SECTION 2 – TENANTS
# =============================================================================

# -----------------------------------------------------------------------------
rpa_list_active_tenants() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  
  _rpa_require_token || return 1

  RPA_RESULT_TENANTS=$(curl -sk -X GET \
    "$(_rpa_base "v1.0" "${RPA_LOCALE}")/tenant?offset=${offset}&limit=${limit}&asc=true&orderBy=name&suspendedOnly=false" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_TENANTS"

}

# -----------------------------------------------------------------------------
rpa_list_suspended_tenants() {
  local offset="${1:-0}"
  local limit="${2:-100}"
  
  _rpa_require_token || return 1

  RPA_RESULT_SUSPENDED_TENANTS=$(curl -sk -X GET \
    "$(_rpa_base "v1.0" "${RPA_LOCALE}")/tenant?offset=${offset}&limit=${limit}&asc=true&orderBy=name&suspendedOnly=true" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_SUSPENDED_TENANTS"

}

# -----------------------------------------------------------------------------
rpa_get_active_tenant_id_by_name() {
  rpa_list_active_tenants
  echo ${RPA_RESULT_TENANTS} | jq '.results[] | select(.name=="'$1'")' | jq .id | sed 's/"//g'
}

# -----------------------------------------------------------------------------
rpa_get_suspended_tenant_id_by_name() {
  rpa_list_suspended_tenants
  echo ${RPA_RESULT_SUSPENDED_TENANTS} | jq '.results[] | select(.name=="'$1'")' | jq .id | sed 's/"//g'
}


# -----------------------------------------------------------------------------
rpa_add_user_to_tenant() {
  local userName="${1:-}"
  local userEmail="${2:-}"
  local roleNames="${3:-}"
  
  #echo "roleNames: $roleNames"
  # roles="Role1,Role2,Rol3"
  # usare getRoleIdByRoleName "${role}" per caricare array 'rolesIDs'
  # declare -a rolesIDs=("43571a1e-dde4-47e2-babf-ddf7118e5d8f" "1bfa57fc-3296-492b-b49a-c602b9772402" "40614b5d-2f00-4a97-b92f-5d4ddbd8ad07")

  _rpa_require_token || return 1

  local payload='{
    "roles":["43571a1e-dde4-47e2-babf-ddf7118e5d8f", "1bfa57fc-3296-492b-b49a-c602b9772402", "40614b5d-2f00-4a97-b92f-5d4ddbd8ad07"],
    "teams":[],
    "users":[
      {"name":"'${userName}'","email":"'${userEmail}'","distinguishedName":"'${userName}'"}
    ]
  }'

  local url="$(_rpa_base "v1.0" "${RPA_LOCALE}")/user/import"
  local response
  response=$(curl -sk -X POST "${url}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"

}

rpa_get_account_info() {
  local url="$(_rpa_base "v1.0" "${RPA_LOCALE}")/account/install-key"
  RPA_ACCOUNT_INFO=$(curl -sk -H "Authorization: Bearer ${_RPA_ACCESS_TK}" -X GET "${url}" | base64 -d)

  _rpa_check_response "$RPA_ACCOUNT_INFO"

}

# -----------------------------------------------------------------------------
# Utility: display tenants JSON structure
rpa_show_active_tenants() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_TENANTS" | jq '{
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

# -----------------------------------------------------------------------------
rpa_show_suspended_tenants() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_SUSPENDED_TENANTS" | jq '{
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

# -----------------------------------------------------------------------------
rpa_create_tenant() {
  local name="$1"
  local admin_name="$2"
  local admin_email="$3"
  
  _rpa_require_token || return 1

  local payload
  payload=$(jq -n \
    --arg  name  "$name" \
    --arg  aname "$admin_name" \
    --arg  aeml  "$admin_email" \
    '{
      name:       $name,
      userName:   $aname,
      userEmail:  $aeml
    }')

  local response
  response=$(curl -sk -X POST "$(_rpa_base)/tenant" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  RPA_RESULT_NEW_TENANT=$(echo "$response" | jq '{ id: .id}')
}

# -----------------------------------------------------------------------------
rpa_suspend_tenant() {
  local tenant_id="$1"
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X PATCH "$(_rpa_base)/tenant/${tenant_id}/suspend" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
}

# -----------------------------------------------------------------------------
rpa_resume_tenant() {
  local tenant_id="$1"
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X PATCH "$(_rpa_base)/tenant/${tenant_id}/resume" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
}

# -----------------------------------------------------------------------------
rpa_delete_tenant() {
  local tenant_id="$1"
  
  _rpa_require_token || return 1

  local response
  response=$(curl -sk -X DELETE "$(_rpa_base "v1.0" "${RPA_LOCALE}")/tenant/${tenant_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$response"
}

# =============================================================================
# SECTION 3 – CREDENTIALS
# =============================================================================
# References (tenant-admin token required):
#   GET    /rpa/api/v1.0/en-US/credential              – list credentials
#   POST   /rpa/api/v1.0/en-US/credential              – create credential
#   GET    /rpa/api/v1.0/en-US/credential/pool         – list pools # NOT SECURE CODE
#   POST   /rpa/api/v1.0/en-US/credential/pool         – create pool # NOT SECURE CODE
# =============================================================================

# -----------------------------------------------------------------------------
# 3.1  LIST CREDENTIALS
# GET /rpa/api/v1.0/en-US/credential?offset=0&limit=20
#
# Response:
# {
#   "total": 4,
#   "results": [
#     { "id": "...", "name": "SAPCred", "description": "...",
#       "type": "UserPassword" }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_credentials() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  RPA_RESULT_CREDENTIALS=$(curl -sk -X GET \
    "$(_rpa_base)/credential?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_CREDENTIALS"
  echo "Credentials retrieved. Use rpa_show_credentials to inspect."
}

# Utility: display credentials JSON structure
rpa_show_credentials() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_CREDENTIALS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      type:        .type
    }]
  }'
}

# -----------------------------------------------------------------------------
# 3.2  CREATE CREDENTIAL
# POST /rpa/api/v1.0/en-US/credential
#
# Payload:
# {
#   "name":        "SAPCred",
#   "description": "SAP service account",
#   "type":        "UserPassword",   // "UserPassword" | "Token"
#   "login":       "sap_user",
#   "password":    "SapPassw0rd!"
# }
# Response:
# { "id": "...", "name": "SAPCred", "type": "UserPassword" }
#
# Parameters:
#   $1  name         – credential name
#   $2  description  – description
#   $3  type         – "UserPassword" (default) or "Token"
#   $4  login        – username / token name
#   $5  password     – password / token value
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/credential" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, type: .type }'
}

# -----------------------------------------------------------------------------
# 3.3  LIST CREDENTIAL POOLS
# GET /rpa/api/v1.0/en-US/credential/pool?offset=0&limit=20
# NOT SECURE CODE – endpoint path inferred; verify against your RPA 30.0.x docs
#
# Response:
# {
#   "total": 2,
#   "results": [
#     { "id": "...", "name": "SAPPool", "description": "...",
#       "credentials": [{ "id": "...", "name": "SAPCred" }] }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_credential_pools() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1
  # NOT SECURE CODE – endpoint path not confirmed in public docs

  RPA_RESULT_CREDENTIAL_POOLS=$(curl -sk -X GET \
    "$(_rpa_base)/credential/pool?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_CREDENTIAL_POOLS"
  echo "Credential pools retrieved. Use rpa_show_credential_pools to inspect."
}

# Utility: display credential pools JSON structure
rpa_show_credential_pools() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_CREDENTIAL_POOLS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      credentials: [.credentials[]? | { id: .id, name: .name }]
    }]
  }'
}

# -----------------------------------------------------------------------------
# 3.4  CREATE CREDENTIAL POOL
# POST /rpa/api/v1.0/en-US/credential/pool
# NOT SECURE CODE – endpoint path inferred; verify against your RPA 30.0.x docs
#
# Payload:
# {
#   "name":          "SAPPool",
#   "description":   "Pool of SAP service accounts",
#   "credentialIds": ["<credId1>", "<credId2>"]
# }
# Response:
# { "id": "...", "name": "SAPPool", "description": "..." }
#
# Parameters:
#   $1  name              – pool name
#   $2  description       – description
#   $3  credential_ids    – JSON array of credential IDs, e.g. '["id1","id2"]'
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/credential/pool" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, description: .description }'
}

# =============================================================================
# SECTION 4 – COMPUTERS
# =============================================================================
# References (tenant-admin token required):
#   GET    /rpa/api/v1.0/en-US/computer                  – list computers
#   GET    /rpa/api/v1.0/en-US/computer/group            – list computer groups
#   POST   /rpa/api/v1.0/en-US/computer/group            – create computer group
#   PUT    /rpa/api/v1.0/en-US/computer/{computerId}     – update computer
# =============================================================================

# -----------------------------------------------------------------------------
# 4.1  LIST COMPUTERS
# GET /rpa/api/v1.0/en-US/computer?offset=0&limit=20
#
# Response:
# {
#   "total": 5,
#   "results": [
#     { "id": "...", "name": "BOT-WIN-01", "status": "Available",
#       "computerGroupId": "...", "multiSession": false }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_computers() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  RPA_RESULT_COMPUTERS=$(curl -sk -X GET \
    "$(_rpa_base)/computer?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_COMPUTERS"
  echo "Computers retrieved. Use rpa_show_computers to inspect."
}

# Utility: display computers JSON structure
rpa_show_computers() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_COMPUTERS" | jq '{
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

# -----------------------------------------------------------------------------
# 4.2  LIST COMPUTER GROUPS
# GET /rpa/api/v1.0/en-US/computer/group?offset=0&limit=20
#
# Response:
# {
#   "total": 2,
#   "results": [
#     { "id": "...", "name": "ProductionBots", "description": "..." }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_computer_groups() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  RPA_RESULT_COMPUTER_GROUPS=$(curl -sk -X GET \
    "$(_rpa_base)/computer/group?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_COMPUTER_GROUPS"
  echo "Computer groups retrieved. Use rpa_show_computer_groups to inspect."
}

# Utility: display computer groups JSON structure
rpa_show_computer_groups() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_COMPUTER_GROUPS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description
    }]
  }'
}

# -----------------------------------------------------------------------------
# 4.3  CREATE COMPUTER GROUP
# POST /rpa/api/v1.0/en-US/computer/group
#
# Payload:
# {
#   "name":        "ProductionBots",
#   "description": "Windows bot farm – production"
# }
# Response:
# { "id": "...", "name": "ProductionBots", "description": "..." }
#
# Parameters:
#   $1  name         – group name
#   $2  description  – optional description
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/computer/group" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, description: .description }'
}

# -----------------------------------------------------------------------------
# 4.4  UPDATE COMPUTER (assign computer group + multi-session)
# PUT /rpa/api/v1.0/en-US/computer/{computerId}
#
# Payload:
# {
#   "computerGroupId": "<groupId>",
#   "multiSession":    true
# }
# Response:
# { "id": "...", "name": "BOT-WIN-01", "computerGroupId": "...",
#   "multiSession": true }
#
# Parameters:
#   $1  computer_id        – computer UUID
#   $2  computer_group_id  – target computer group UUID
#   $3  multi_session      – true | false  (default: false)
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X PUT "$(_rpa_base)/computer/${computer_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{
    id:              .id,
    name:            .name,
    computerGroupId: .computerGroupId,
    multiSession:    .multiSession
  }'
}

# =============================================================================
# SECTION 5 – PROJECTS
# =============================================================================
# References (tenant-admin token required):
#   GET    /rpa/api/v1.0/en-US/project               – list projects
#   POST   /rpa/api/v1.0/en-US/project               – create project
# =============================================================================

# -----------------------------------------------------------------------------
# 5.1  LIST PROJECTS
# GET /rpa/api/v1.0/en-US/project?offset=0&limit=20
#
# Response:
# {
#   "total": 3,
#   "results": [
#     { "id": "...", "name": "SAPAutomation", "description": "...",
#       "teamId": "..." }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_projects() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  RPA_RESULT_PROJECTS=$(curl -sk -X GET \
    "$(_rpa_base)/project?offset=${offset}&limit=${limit}&asc=true&orderBy=name" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_PROJECTS"
  echo "Projects retrieved. Use rpa_show_projects to inspect."
}

# Utility: display projects JSON structure
rpa_show_projects() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_PROJECTS" | jq '{
    total:   .total,
    results: [.results[]? | {
      id:          .id,
      name:        .name,
      description: .description,
      teamId:      .teamId
    }]
  }'
}

# -----------------------------------------------------------------------------
# 5.2  CREATE PROJECT (with team access and description)
# POST /rpa/api/v1.0/en-US/project
#
# Payload (with team restriction):
# {
#   "name":        "SAPAutomation",
#   "description": "Automates SAP workflows",
#   "teamId":      "<teamId>"
# }
# Payload (without team restriction):
# {
#   "name":        "SAPAutomation",
#   "description": "Automates SAP workflows"
# }
# Response:
# { "id": "...", "name": "SAPAutomation", "description": "...", "teamId": "..." }
#
# Parameters:
#   $1  name         – project name
#   $2  description  – project description
#   $3  team_id      – (optional) team UUID for access restriction
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/project" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{ id: .id, name: .name, description: .description, teamId: .teamId }'
}

# =============================================================================
# SECTION 6 – BOTS
# =============================================================================
# References (tenant-admin token required):
#   GET    /rpa/api/v2.0/workspace/{workspaceId}/bots   – list bots (v2)
#   POST   /rpa/api/v1.0/en-US/bot                      – create bot
#   PUT    /rpa/api/v1.0/en-US/bot/{botId}              – update bot
#
# NOTE: The list-bots endpoint uses the v2.0 workspace-scoped path
#       (as seen in commons.sh: rpaBotsList).  Create/update still use v1.0.
# =============================================================================

# -----------------------------------------------------------------------------
# 6.1  LIST BOTS
# GET /rpa/api/v2.0/workspace/{workspaceId}/bots
#
# Requires _WORKSPACE_ID to be set (populated by workspace discovery or
# set manually: export _WORKSPACE_ID="<uuid>").
#
# Response:
# {
#   "total": 10,
#   "results": [
#     { "id": "...", "name": "SAPBot", "description": "...",
#       "scriptId": "...", "scriptVersion": "1",
#       "computerGroupId": "...", "status": "Enabled" }
#   ]
# }
# -----------------------------------------------------------------------------
rpa_list_bots() {
  local offset="${1:-0}"
  local limit="${2:-50}"
  
  _rpa_require_token || return 1

  if [[ -z "${_WORKSPACE_ID:-}" ]]; then
    echo "ERROR: _WORKSPACE_ID is not set. Export it before calling rpa_list_bots." >&2
    return 1
  fi

  RPA_RESULT_BOTS=$(curl -sk -X GET \
    "${PAK_HOST}/rpa/api/v2.0/workspace/${_WORKSPACE_ID}/bots?offset=${offset}&limit=${limit}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Accept: application/json")

  _rpa_check_response "$RPA_RESULT_BOTS"
  echo "Bots retrieved. Use rpa_show_bots to inspect."
}

# Utility: display bots JSON structure
rpa_show_bots() {
  _rpa_require_jq || return 1
  echo "$RPA_RESULT_BOTS" | jq '{
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

# -----------------------------------------------------------------------------
# 6.2  CREATE BOT
# POST /rpa/api/v1.0/en-US/bot
#
# Payload:
# {
#   "name":            "SAPBot",
#   "description":     "Automates SAP invoice processing",
#   "scriptId":        "<scriptId>",
#   "scriptVersion":   "1",
#   "computerGroupId": "<computerGroupId>"
# }
# Response:
# { "id": "...", "name": "SAPBot", "description": "...",
#   "scriptId": "...", "scriptVersion": "1", "computerGroupId": "..." }
#
# Parameters:
#   $1  name               – bot name
#   $2  description        – bot description
#   $3  script_id          – UUID of the WAL script
#   $4  script_version     – version number (default: "1")
#   $5  computer_group_id  – UUID of the computer group
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X POST "$(_rpa_base)/bot" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{
    id:              .id,
    name:            .name,
    description:     .description,
    scriptId:        .scriptId,
    scriptVersion:   .scriptVersion,
    computerGroupId: .computerGroupId
  }'
}

# -----------------------------------------------------------------------------
# 6.3  UPDATE BOT
# PUT /rpa/api/v1.0/en-US/bot/{botId}
#
# Payload:
# {
#   "description":     "Updated description",
#   "scriptId":        "<newScriptId>",
#   "scriptVersion":   "2",
#   "computerGroupId": "<newComputerGroupId>"
# }
# Response:
# { "id": "...", "name": "SAPBot", "description": "...",
#   "scriptId": "...", "scriptVersion": "2", "computerGroupId": "..." }
#
# Parameters:
#   $1  bot_id             – bot UUID
#   $2  description        – new description
#   $3  script_id          – new script UUID
#   $4  script_version     – new script version (default: "1")
#   $5  computer_group_id  – new computer group UUID
# -----------------------------------------------------------------------------
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
  response=$(curl -sk -X PUT "$(_rpa_base)/bot/${bot_id}" \
    -H "Authorization: Bearer ${_RPA_ACCESS_TK}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$payload")

  _rpa_check_response "$response"
  echo "$response" | jq '{
    id:              .id,
    name:            .name,
    description:     .description,
    scriptId:        .scriptId,
    scriptVersion:   .scriptVersion,
    computerGroupId: .computerGroupId
  }'
}

# =============================================================================
# SECTION 7 – END-TO-END EXAMPLE: User Onboarding with Roles
# =============================================================================
# Demonstrates the full CP4BA Zen → RPA user onboarding sequence:
#   Step 1  – Authenticate via CP4BA Zen (commons.sh loginAsRpaAdmin)
#   Step 2  – Create a team
#   Step 3  – Create user with specified role
#   Step 4  – Add user to team
#
# curl RAW EXAMPLES (for reference, replace placeholders with real values):
#
# ## Step 1 – Get IAM identity token
#   curl -ks -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" \
#        -d "grant_type=password&username=rpaAdmin&password=Passw0rd!&scope=openid" \
#        "https://<CONSOLE_HOST>/idprovider/v1/auth/identitytoken"
#
# ## Step 2 – Validate Auth to get Zen token
#   curl -ks -H "username:rpaAdmin" -H "iam-token: <IAM_TOKEN>" \
#        "https://<PAK_HOST>/v1/preauth/validateAuth"
#
# ## Step 3 – Zen token login (get OIDC token + tenantId)
#   curl -ks --cookie "ibm-private-cloud-session=<ZEN_TOKEN>" \
#        "https://<PAK_HOST>/rpa/api/zen-token-login"
#
# ## Step 4 – Get RPA access token
#   curl -ks -H "Content-Type: application/x-www-form-urlencoded" \
#        -d "grant_type=password" \
#        --cookie "ibm-private-cloud-session=<ZEN_TOKEN>" \
#        -H "tenantId:<TENANT_ID>" \
#        -H "oidc-access-token:<OIDC_TOKEN>" \
#        "https://<PAK_HOST>/rpa/api/v1.0/token"
#
# ## Step 5 – Create user with role RpaOperator
#   curl -ks -X POST \
#        "https://<PAK_HOST>/rpa/api/v1.0/en-US/user" \
#        -H "Authorization: Bearer <RPA_ACCESS_TK>" \
#        -H "Content-Type: application/json" \
#        -d '{
#              "login":    "john.doe",
#              "name":     "John Doe",
#              "email":    "john.doe@example.com",
#              "password": "Passw0rd!",
#              "roles":    [{ "name": "RpaOperator" }]
#            }'
#
# ## Step 6 – Create user with role RpaDeveloper
#   curl -ks -X POST \
#        "https://<PAK_HOST>/rpa/api/v1.0/en-US/user" \
#        -H "Authorization: Bearer <RPA_ACCESS_TK>" \
#        -H "Content-Type: application/json" \
#        -d '{
#              "login":    "jane.smith",
#              "name":     "Jane Smith",
#              "email":    "jane.smith@example.com",
#              "password": "Passw0rd!",
#              "roles":    [{ "name": "RpaDeveloper" }]
#            }'
#
# ## Step 7 – Create team
#   curl -ks -X POST \
#        "https://<PAK_HOST>/rpa/api/v1.0/en-US/team" \
#        -H "Authorization: Bearer <RPA_ACCESS_TK>" \
#        -H "Content-Type: application/json" \
#        -d '{ "name": "AutomationTeam", "description": "Team for RPA automations" }'
# =============================================================================

rpa_example_onboard_user() {
  local new_login="${1:-newuser}"
  local new_email="${2:-newuser@example.com}"
  local new_name="${3:-New User}"
  local new_pass="${4:-Passw0rd!}"
  # Valid role names:
  #   RpaPlatformAdministrator | RpaTenantAdministrator | RpaOperator
  #   RpaDeveloper | RpaBusinessAnalyst | RpaAuditor
  local role="${5:-RpaOperator}"

  

  echo ""
  echo "--- STEP 1: Authenticate via CP4BA Zen (using commons.sh) ---"
  echo "  Set these env vars first:"
  echo "    export CP4BA_INST_RPA_NAMESPACE='cp4ba'"
  echo "    export _USER_ADMIN_NAME='rpaAdmin'"
  echo "    export _USER_ADMIN_PWD='Passw0rd!'"
  echo "  Then call: loginAsRpaAdmin"
  echo "  This populates: _RPA_ACCESS_TK, _TENANT_ID, PAK_HOST"
  echo ""

  _rpa_require_token || { echo "Please run loginAsRpaAdmin first."; return 1; }

  echo "--- STEP 2: Create a team (if needed) ---"
  rpa_create_team "AutomationTeam" "Team for RPA automations"
  local team_id
  team_id=$(echo "$RPA_RESULT_TEAMS" | jq -r '.id // empty')

  echo ""
  echo "--- STEP 3: Create user with role: ${role} ---"
  rpa_create_user \
    "$new_login" \
    "$new_name" \
    "$new_email" \
    "$new_pass" \
    "[{\"name\":\"${role}\"}]"

  echo ""
  echo "--- STEP 4: Resolve new user ID ---"
  rpa_list_users 0 100 "$new_login"
  local user_id
  user_id=$(echo "$RPA_RESULT_USERS" | jq -r \
    --arg login "$new_login" '.results[]? | select(.login == $login) | .id' | head -1)

  echo ""
  echo "--- STEP 5: Add user to team ---"
  if [[ -n "${user_id:-}" && -n "${team_id:-}" ]]; then
    rpa_add_user_to_team "$team_id" "$user_id"
  else
    echo "WARN: Could not resolve user_id='${user_id}' or team_id='${team_id}' — skipping team assignment."
  fi

  echo ""
  echo "--- Onboarding complete for: ${new_login} (role: ${role}) ---"
}

# =============================================================================
# SECTION 8 – CONVENIENCE: show all cached result variables
# =============================================================================

rpa_show_all() {
  _rpa_require_jq || return 1
  
  echo "--- Users ---";             rpa_show_users            2>/dev/null || echo "(empty)"
  echo "--- Roles ---";             rpa_show_roles            2>/dev/null || echo "(empty)"
  echo "--- Teams ---";             rpa_show_teams            2>/dev/null || echo "(empty)"
  echo "--- Tenants ---";           rpa_show_active_tenants          2>/dev/null || echo "(empty)"
  echo "--- Credentials ---";       rpa_show_credentials      2>/dev/null || echo "(empty)"
  echo "--- Credential Pools ---";  rpa_show_credential_pools 2>/dev/null || echo "(empty)"
  echo "--- Computers ---";         rpa_show_computers        2>/dev/null || echo "(empty)"
  echo "--- Computer Groups ---";   rpa_show_computer_groups  2>/dev/null || echo "(empty)"
  echo "--- Projects ---";          rpa_show_projects         2>/dev/null || echo "(empty)"
  echo "--- Bots ---";              rpa_show_bots             2>/dev/null || echo "(empty)"
}

# =============================================================================
# LOAD MESSAGE
# =============================================================================
# echo "IBM RPA Day-2 Automation functions loaded (CP4BA / Zen auth)."
# echo ""
# echo "PREREQUISITE: source ./knowledge/commons.sh, then call loginAsRpaAdmin."
# echo ""
# echo "Available functions:"
# echo "  Access Admin  : rpa_list_users, rpa_create_user"
# echo "                  rpa_list_roles, rpa_create_role"
# echo "                  rpa_list_teams, rpa_create_team, rpa_add_user_to_team"
# echo "  Tenants       : rpa_list_active_tenants, rpa_create_tenant,"
# echo "                  rpa_suspend_tenant, rpa_delete_tenant"
# echo "  Credentials   : rpa_list_credentials, rpa_create_credential,"
# echo "                  rpa_list_credential_pools, rpa_create_credential_pool"
# echo "  Computers     : rpa_list_computers, rpa_list_computer_groups,"
# echo "                  rpa_create_computer_group, rpa_update_computer"
# echo "  Projects      : rpa_list_projects, rpa_create_project"
# echo "  Bots          : rpa_list_bots, rpa_create_bot, rpa_update_bot"
# echo "  Show/Inspect  : rpa_show_users, rpa_show_roles, rpa_show_teams,"
# echo "                  rpa_show_active_tenants, rpa_show_credentials,"
# echo "                  rpa_show_credential_pools, rpa_show_computers,"
# echo "                  rpa_show_computer_groups, rpa_show_projects,"
# echo "                  rpa_show_bots, rpa_show_all"
# echo "  Example       : rpa_example_onboard_user <login> <email> <name> <pass> <role>"

getFieldFromJson () {
  _JSON="$1"
  _FIELD="$2"
  echo "${_JSON}" | jq .["${_FIELD}"] | sed 's/"//g'
}

#==============================================================
# Delete active tenant
deleteActiveTenant () {
  local _tenantName="$1"
  if [[ ! -z "${_tenantName}" ]]; then
    _TID=$(rpa_get_active_tenant_id_by_name "${_tenantName}")
    if [[ ! -z "${_TID}" ]]; then
      rpa_suspend_tenant "${_TID}"
      rpa_delete_tenant "${_TID}"
    else
      log_error "deleteActiveTenant: '${_tenantName}' not found"
    fi
  else
    log_error "deleteActiveTenant: Empty tenant name"
  fi
}

#===================================================================
# TESTS
#===================================================================

export CP4BA_INST_RPA_NAMESPACE="cp4ba-rpa-34-managed-1"        
export _USER_ADMIN_NAME="rpaadmin"
export _USER_ADMIN_PWD="dem0s"

testTenantCreate () {
  loginAsRpaAdmin

  _name="TENANT-A"
  _admin="rpatenantadmin1" 
  _adminmail="rpatenantadmin1@vuxrpaprod.net"

  rpa_list_active_tenants
  rpa_show_active_tenants
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}"
  echo "RPA_RESULT_NEW_TENANT: $RPA_RESULT_NEW_TENANT"
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
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}"
  echo "RPA_RESULT_NEW_TENANT: $RPA_RESULT_NEW_TENANT"
  rpa_list_active_tenants
  rpa_show_active_tenants

  sleep 10
  deleteActiveTenant "${_name}"

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
  
  rpa_create_tenant "${_name}" "${_admin}" "${_adminmail}"
  echo "RPA_RESULT_NEW_TENANT: $RPA_RESULT_NEW_TENANT"
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

  echo "User:"
  echo $_USER_DETAILS | jq .

  rpa_get_account_info
  echo "${RPA_ACCOUNT_INFO}" | jq .  

  rpa_list_active_tenants
  rpa_show_active_tenants

  rpa_list_tenant_users
  echo "${RPA_RESULT_TENANT_USERS}" | jq .

  rpa_list_users_to_import 0 100 "rpa"
  echo "${RPA_RESULT_USERS}" | jq .


  # the user is added to tenant administered by logged in tenant admin
  rpa_add_user_to_tenant "rpauser11" "rpauser11@vuxrpaprod.net"

}
#=====================================
# testTenantCreate
# testTenantCreateDelete
# testTenantCreateSuspend
# testTenantDelete

#=====================================
# testLoginAsTenantAdminAndCreateUsers

echo "Work in progress, do not use this script"
