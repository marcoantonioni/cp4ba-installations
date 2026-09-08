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
      echo -e  "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      echo -e  "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  echo -e  "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}


usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me${_CLR_NC}"
}



#----------------------------------------------------
_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"


_ROTOR="|/-\\|/-\\"
_ROTOR_LEN=${#_ROTOR}
_DENV_START_SECONDS=$SECONDS
_CSV_START_SECONDS=0

if [[ ! -f "./${_RPA_CFG}" ]]; then
  echo "Error config file '${_RPA_CFG}' not found !"
  echo "example:"
  echo "export _RPA_CFG=./env1-rpa1.properties"
  echo "./$_me"
  exit 1
fi

source "./${_RPA_CFG}"

namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2>/dev/null | grep $1 2>/dev/null | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

updateRotor () {
  _seconds=$1
  _CSV_NAME=$2
  _ROTOR_CHAR_OFF=$((_seconds % _ROTOR_LEN))
  _ROTOR_CHAR="${_ROTOR:_ROTOR_CHAR_OFF:1}"

  NOW_SECONDS=$SECONDS
  ELAPSED_SECONDS=$(( $NOW_SECONDS - $_CSV_START_SECONDS ))
  TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
  TOT_MINUTES=$(( $(($ELAPSED_SECONDS / 60)) % 60))
  TOT_HOURS=$(( $(($ELAPSED_SECONDS / 3600)) % 24))

  echo -e -n "( ${_CLR_YELLOW}${_ROTOR_CHAR}${_CLR_GREEN} ) waiting for CSV '${_CLR_YELLOW}$_CSV_NAME${_CLR_GREEN}' installation to complete, elapsed time [${_CLR_YELLOW}${TOT_HOURS}${_CLR_GREEN}h:${_CLR_YELLOW}${TOT_MINUTES}${_CLR_GREEN}m:${_CLR_YELLOW}${TOT_SECONDS}${_CLR_GREEN}s]\033[0K\r"
}

waitCSVSucceeded () {

  _CSV_NAME=$1
  _seconds=0
  _CSV_START_SECONDS=$SECONDS
  while [ true ]
  do
    _CSV_NAME_VERSION=$(oc get csv -n ${_RPA_NAMESPACE} | grep "$_CSV_NAME" | awk '{print $1}')
    if [[ ! -z "${_CSV_NAME_VERSION}" ]]; then
      while [ true ]
      do
          PHASE=$(oc get csv -n ${_RPA_NAMESPACE} $_CSV_NAME_VERSION -o jsonpath="{.status.phase}")
          if [ "${PHASE}" = "Succeeded" ]; then
            if [ $_seconds -gt 0 ]; then
              echo ""
            fi
            echo -e "CSV '${_CLR_YELLOW}$_CSV_NAME_VERSION${_CLR_GREEN}' installation completed."
            break
          else
            updateRotor $_seconds $_CSV_NAME_VERSION
            ((_seconds=_seconds+1))
            sleep 1
          fi
      done
      break
    else
      updateRotor $_seconds $_CSV_NAME
      ((_seconds=_seconds+1))
      sleep 1
    fi
  done

}

removeOldRPADb () {
  oc delete deployment -n ${_RPA_NAMESPACE} ${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME} 2> /dev/null 1> /dev/null
  oc delete pvc -n ${_RPA_NAMESPACE} ${CP4BA_INST_RPA_PVC_NAME} 2> /dev/null 1> /dev/null

}

createRPADbSecrets () {

  if [[ -z "${CP4BA_INST_RPA_DB_SECRET_NAME}" ]]; then
    export CP4BA_INST_RPA_DB_SECRET_NAME="rpa-mssql"
    echo -e  "${_CLR_GREEN}Value for CP4BA_INST_RPA_DB_SECRET_NAME is not set, default to '${CP4BA_INST_RPA_DB_SECRET_NAME}' value"
  fi
  if [[ -z "${CP4BA_INST_RPA_DB_PWD}" ]]; then
    export CP4BA_INST_RPA_DB_PWD="dem0s-dem0s"
    echo -e  "${_CLR_GREEN}Value for CP4BA_INST_RPA_DB_PWD is not set, default to '${CP4BA_INST_RPA_DB_PWD}' value"
  fi

  _SECRET_NAME="${CP4BA_INST_RPA_DB_SECRET_NAME}"
  # echo -e "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${_RPA_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${_RPA_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=SA_PASSWORD="${CP4BA_INST_RPA_DB_PWD}" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e  "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
  oc label secret ${_SECRET_NAME} cp4ba.ibm.com/backup-type=mandatory -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null

}

createRPAPVC () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ${CP4BA_INST_RPA_PVC_NAME}
  namespace: ${_RPA_NAMESPACE}
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: ${CP4BA_INST_RPA_PVC_SIZE}
  storageClassName: ${CP4BA_INST_SC_BLOCK}
EOF

}

createRPADatabase () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME}
  namespace: ${_RPA_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: mssql
        image: ${CP4BA_INST_RPA_DB_IMAGE}
        ports:
        - containerPort: 1433
        env:
        - name: MSSQL_PID
          value: "Developer"
        - name: ACCEPT_EULA
          value: "Y"
        - name: SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${CP4BA_INST_RPA_DB_SECRET_NAME}
              key: SA_PASSWORD
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      serviceAccount: ${CP4BA_INST_RPA_SA}
      securityContext:
        runAsUser: 0
        runAsGroup: 0   
        fsGroup: 0
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: ${CP4BA_INST_RPA_PVC_NAME}
EOF

}

createRPADatabaseServices () {

  oc delete service -n ${_RPA_NAMESPACE} ${CP4BA_INST_RPA_SERVICE_NODEPORT_NAME} 2> /dev/null 1> /dev/null
  oc delete service -n ${_RPA_NAMESPACE} ${CP4BA_INST_RPA_SERVICE_NAME} 2> /dev/null 1> /dev/null

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: v1
kind: Service
metadata:
  name: ${CP4BA_INST_RPA_SERVICE_NODEPORT_NAME}
  namespace: ${_RPA_NAMESPACE}
spec:
  selector:
    app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  ports:
    - protocol: TCP
      port: ${CP4BA_INST_RPA_NODE_PORT}
      targetPort: 1433
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: ${CP4BA_INST_RPA_SERVICE_NAME}
  namespace: ${_RPA_NAMESPACE}
spec:
  selector:
    app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
EOF

}

deployRPAMsSqlServer () {
  echo -e  "Installing MSSQL Server for RPA capability"

  removeOldRPADb

  createRPADbSecrets
  createRPAPVC
  createRPADatabase
  createRPADatabaseServices  
}

#-------------------------------------------------

installLicensingOperator () {
  echo "Installing IBM Licensing Operator"

cat <<EOF | oc create -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
    name: ibm-licensing-catalog
    namespace: ibm-licensing
spec:
  displayName: IBM License Service Catalog
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/ibm-licensing-catalog
  updateStrategy:
    registryPoll:
      interval: 45m
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-licensing-operator-app
  namespace: ibm-licensing
spec:
  channel: $_LICENSING_CHANNEL
  installPlanApproval: Automatic
  name: ibm-licensing-operator-app
  source: ibm-licensing-catalog
  sourceNamespace: ${_RPA_NAMESPACE}
EOF

}

#--------------------------------
# RPA env

createRpaSecrets () {
  oc create secret docker-registry ibm-entitlement-key \
  --docker-server=cp.icr.io \
  --docker-username=cp \
  --docker-password="${CP4BA_AUTO_ENTITLEMENT_KEY}" \
  --namespace=${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null

  # db secret
  oc create secret generic rpa-db -n ${_RPA_NAMESPACE} \
    --from-literal=AddressContext="${_RPA_DB_CONN_PARAMS_ADDRESS}" \
    --from-literal=AutomationContext="${_RPA_DB_CONN_PARAMS_AUTOMATION}" \
    --from-literal=KnowledgeBase="${_RPA_DB_CONN_PARAMS_KNOWLEDGE}" \
    --from-literal=WordnetContext="${_RPA_DB_CONN_PARAMS_WORDNET}" \
    --from-literal=AuditContext="${_RPA_DB_CONN_PARAMS_AUDIT}" 2> /dev/null 1> /dev/null

  # tenant owner
  oc create secret generic rpa-first-tenant-owner -n ${_RPA_NAMESPACE} \
    --from-literal=name=${CP4BA_INST_RPA_TENANT_OWNER_NAME} \
    --from-literal=email=${CP4BA_INST_RPA_TENANT_OWNER_EMAIL} 2> /dev/null 1> /dev/null

  # smtp secret
  oc create secret generic rpa-smtp -n ${_RPA_NAMESPACE} \
    --from-literal=username=${_RPA_SMTP_USER} \
    --from-literal=password=${_RPA_SMTP_PASSWORD} 2> /dev/null 1> /dev/null

  # redis secret https://www.ibm.com/docs/en/rpa/30.0.x?topic=platform-creating-rpa-secrets#creating-a-redis-password-secret
  oc create secret generic rpa-redis-rpa -n ${_RPA_NAMESPACE} \
    --from-literal=default_password=${_RPA_ADMIN_PWD} 2> /dev/null 1> /dev/null

  oc label secret rpa-redis-rpa app.kubernetes.io/component=rpa -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/instance=rpa -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/managed-by=ibm-rpa-operator -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/name=redis -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa rpa.automation.ibm.com/cr-name=rpa -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null

}

createServiceAccount () {

cat <<EOF | oc create -f - 2> /dev/null 1> /dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ibm-cp4ba-anyuid
  namespace: ${_RPA_NAMESPACE}
imagePullSecrets:
- name: 'ibm-entitlement-key'
EOF

oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${_RPA_NAMESPACE} 2> /dev/null 1> /dev/null

}

createOperatorGroup () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: operators.coreos.com/v1alpha2 
kind: OperatorGroup 
metadata: 
  name: rpa-group
  namespace: ${_RPA_NAMESPACE}
spec: 
  targetNamespaces: 
  - ${_RPA_NAMESPACE}
EOF

}


installFoundationalServices () {

cat <<EOF | oc create -f - 2> /dev/null 1> /dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
    name: opencloud-operators
    namespace: ${_RPA_NAMESPACE}
spec:
    displayName: IBMCS Operators
    publisher: IBM
    sourceType: grpc
    image: icr.io/cpopen/ibm-common-service-catalog:4.10
    updateStrategy:
      registryPoll:
          interval: 45m
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-common-service-operator
  namespace: ${_RPA_NAMESPACE}
spec:
  channel: v4.10
  installPlanApproval: Automatic
  name: ibm-common-service-operator
  source: opencloud-operators
  sourceNamespace: ${_RPA_NAMESPACE}
EOF

}



installOperatorCatalog () {

cat <<EOF | oc create -f - 2> /dev/null 1> /dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: ${_RPA_NAMESPACE}
spec:
  displayName: IBM Operator Catalog
  image: icr.io/cpopen/ibm-operator-catalog:latest
  publisher: IBM
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

  waitCSVSucceeded "operand-deployment-lifecycle-manager"
}

installMQOperator () {

cat << EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-mq
  namespace: ${_RPA_NAMESPACE}
spec:
  channel: $_MQ_CHANNEL
  installPlanApproval: Automatic
  name: ibm-mq 
  source: ibm-operator-catalog 
  sourceNamespace: ${_RPA_NAMESPACE}
EOF

  waitCSVSucceeded "ibm-mq."

}

installMsSqlTools () {

cat <<EOF | oc create -f - 2> /dev/null 1> /dev/null
kind: Pod
apiVersion: v1
metadata:
  name: mssql-tools
  namespace: ${_RPA_NAMESPACE}
  labels:
    app: mssql-tools
spec:
  containers:
    - name: mssql-tools
      image: 'mcr.microsoft.com/mssql-tools'
      command: [ "/bin/bash", "-c", "sleep infinity" ]
EOF

  while [ true ]
  do
    PHASE=$(oc get pod -n ${_RPA_NAMESPACE} mssql-tools -o jsonpath='{.status.phase}')
    if [ "${PHASE}" = "Running" ]; then
      #echo "${mssql-tools} Running"
      break
    else
      #echo -n "."
      sleep 5
    fi
  done

}

verifyDatabases () {
  echo "Checking databases in server at FQDN: $_RPA_SERVICE_NAME.${_RPA_NAMESPACE}.svc.cluster.local"

  oc rsh -n ${_RPA_NAMESPACE} mssql-tools "/opt/mssql-tools/bin/sqlcmd" -C -S "$_RPA_SERVICE_NAME.${_RPA_NAMESPACE}.svc.cluster.local" -U sa -P $_RPA_DB_PWD -Q "SELECT name, database_id, create_date FROM sys.databases;" | grep -E "automation|knowledge|wordnet|address|audit"

  for dbName in automation knowledge wordnet address audit 
  do
    echo ">>> DB $dbName"
    oc rsh -n ${_RPA_NAMESPACE} mssql-tools "/opt/mssql-tools/bin/sqlcmd" -C -S "$_RPA_SERVICE_NAME.${_RPA_NAMESPACE}.svc.cluster.local" -U sa -P $_RPA_DB_PWD -Q "use "$dbName"; select s.name As SchemaName, t.name As TableName From sys.schemas s Inner Join sys.tables t On s.schema_id = t.schema_id Order By SchemaName, TableName;"
  done

# /opt/mssql-tools18/bin/sqlcmd -C -U sa -P dem0s-dem0s -Q "use automation; select s.name As SchemaName, t.name As TableName From sys.schemas s Inner Join sys.tables t On s.schema_id = t.schema_id Order By SchemaName, TableName;"
}

createDatabases () {
  echo -e "Creating databases in server at FQDN: ${_CLR_YELLOW}$_RPA_SERVICE_NAME.${_RPA_NAMESPACE}.svc.cluster.local${_CLR_NC}"
  oc rsh -n ${_RPA_NAMESPACE} mssql-tools "/opt/mssql-tools/bin/sqlcmd" -C -S "$_RPA_SERVICE_NAME.${_RPA_NAMESPACE}.svc.cluster.local" -U sa -P $_RPA_DB_PWD -Q "create database [automation]; create database [knowledge]; create database [wordnet]; create database [address]; create database [audit];" 2> /dev/null 1> /dev/null

  if [[ "${_RPA_VERIFY_DB}" = "true" ]]; then
    verifyDatabases
  fi

}

installRpaOperator () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: operators.coreos.com/v1alpha1 
kind: Subscription 
metadata: 
  name: rpa-subscription 
  namespace: ${_RPA_NAMESPACE}
spec: 
  channel: $_RPA_CHANNEL
  installPlanApproval: Automatic 
  name: ibm-automation-rpa 
  source: ibm-operator-catalog
  sourceNamespace: ${_RPA_NAMESPACE}
EOF

  waitCSVSucceeded "ibm-automation-rpa."
}

createRpaCR () {

cat <<EOF | oc create -f - 2> /dev/null 1> /dev/null
apiVersion: rpa.automation.ibm.com/v1
kind: RoboticProcessAutomation
metadata:
  name: $_RPA_INSTANCE_NAME
  namespace: ${_RPA_NAMESPACE}
spec:
  license:
    accept: true
    includeSWCUpload: true
  #createRoutes: true
  #webDriverUpdates:
  #  enabled: true
  #systemQueueProvider:
  #  highAvailability: false
  #ui:
  #  replicas: 1
  #hotStorageCleanup:
  #  enabled: true
  version: ${_RPA_VERSION}
  iam:
    route: cpd
  zen:
    managed: $_RPA_MANAGED
  fileStorageClass: ${_SC_FILE}
  blockStorageClass: ${_SC_BLOCK}
  sizeMapping:
    watson-nlp:
      replicas: 1
  api:
    #replicas: 1
    databaseConnectionSecretName: rpa-db
    firstTenant:
      name: ${_RPA_TENANT_NAME}
      ownerSecretName: rpa-first-tenant-owner
    smtp:
      port: 587
      server: mail.cp4ba-collateral.svc.cluster.local
      userSecretName: rpa-smtp
  #antivirus:
  #  replicas: 1
  tls: {}
  audit:
    forwardingEnabled: false
  #ocr:
  #  replicas: 1
EOF

}


setupRpaResources () {
  if [[ "${_RPA_MANAGED}" = "true" ]]; then
    createServiceAccount
    createOperatorGroup
    installFoundationalServices
  fi 

  installOperatorCatalog
  installMQOperator
  installRpaOperator
  createRpaSecrets
  deployRPAMsSqlServer
  sleep 10
  installMsSqlTools
  sleep 30
  createDatabases
  sleep 10
  createRpaCR
  if [[ "${_RPA_MANAGED}" = "true" ]]; then
    waitCSVSucceeded "ibm-iam-operator."
    waitCSVSucceeded "ibm-zen-operator."
  fi

  while [ true ]; do
    _COMPLETION=$(oc get RoboticProcessAutomation -n ${_RPA_NAMESPACE} rpa -o jsonpath='{.status.conditions[*]}' | jq 'select(.reason=="Progress")' | jq .message | sed 's/"//g')
    if [[ "$_COMPLETION" = "100%" ]]; then
      echo ""
      echo -e "RPA resource configuration 100% completed"   
      break
    else
      echo -e -n "RPA resource configuration $_COMPLETION completed, wait...\033[0K\r"      
      sleep 5
    fi
  done
}

checkRpaManagedMode () {
  if [[ "${_RPA_MANAGED}" = "false" ]]; then
    echo -e "Checking resources for unmanaged RPA deployment"
    namespaceExist "${_RPA_NAMESPACE}"
    if [ $? -eq 0 ]; then
      echo -e "Error, namespace '${_CLR_YELLOW}${_RPA_NAMESPACE}${_CLR_GREEN}' not found."
      echo -e "For unmanaged RPA deployment select a namespace with ZenService already installed."
      exit 1
    else
      _zenServiceInstalled=$(oc get zenservices --no-headers -n ${_RPA_NAMESPACE} | wc -l)
      if [ $_zenServiceInstalled -eq 1 ]; then

        while [ true ]; do
          _COMPLETION=$(oc get zenservices -n ${_RPA_NAMESPACE} iaf-zen-cpdservice -o jsonpath='{.status.progress}' | sed 's/"//g')
          if [[ "$_COMPLETION" = "100%" ]]; then
            echo -e "Zenservices resource configuration 100% completed"   
            break
          else
            echo -e -n "Zenservices resource configuration $_COMPLETION completed, wait...\033[0K\r"      
            sleep 5
          fi
        done

      else
        echo -e "Error, namespace '${_CLR_YELLOW}${_RPA_NAMESPACE}${_CLR_GREEN}' found but no ZenService installed."
        echo -e "For unmanaged RPA deployment select a namespace with ZenService already installed."
        exit 1
      fi
    fi
  fi

}

waitInstallationCompleted () {
  NOW_SECONDS=$SECONDS
  ELAPSED_SECONDS=$(( $NOW_SECONDS - $_DENV_START_SECONDS ))
  TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
  TOT_MINUTES=$(( $(($ELAPSED_SECONDS / 60)) % 60))
  TOT_HOURS=$(( $(($ELAPSED_SECONDS / 3600)) % 24))

  echo -e "IBM RPA installation completed in ${_CLR_YELLOW}${TOT_HOURS}${_CLR_GREEN}h:${_CLR_YELLOW}${TOT_MINUTES}${_CLR_GREEN}m:${_CLR_YELLOW}${TOT_SECONDS}${_CLR_GREEN}s."

  _CPD_URL="https://"$(oc get route -n ${_RPA_NAMESPACE} cpd -o jsonpath="{.spec.host}")
  echo -e "RPA environment URL: ${_CPD_URL}/rpa/ui"
  echo -e "RPA tenant owner: ${CP4BA_INST_RPA_TENANT_OWNER_NAME}"
  if [[ "${CP4BA_INST_RPA_TENANT_OWNER_NAME}" = "cpadmin" ]]; then
    _CPADMIN_PWD=$(oc get secret -n ${_RPA_NAMESPACE} platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d)
    echo -e "RPA admin user credentials: cpadmin / ${_CPADMIN_PWD}"
  fi

}

#-----------------------------------------
installRpaStandalone () {

  checkRpaManagedMode

  namespaceExist "ibm-licensing"
  if [ $? -eq 0 ]; then
    oc new-project "ibm-licensing" 2> /dev/null 1> /dev/null
    installLicensingOperator
  fi

  if [[ "${_RPA_MANAGED}" = "true" ]]; then
    namespaceExist "${_RPA_NAMESPACE}"
    if [ $? -eq 0 ]; then
      oc new-project "${_RPA_NAMESPACE}" 2> /dev/null 1> /dev/null
    else
      echo -e "Namespace '${_CLR_YELLOW}${_RPA_NAMESPACE}${_CLR_GREEN}' already present, skip installation."
      exit 1
    fi
  fi

  setupRpaResources

  waitInstallationCompleted

}

echo "=============================================================="
echo -e "${_CLR_GREEN}Deploying IBM RPA standalone resources (RPA version:${_CLR_YELLOW}${_RPA_VERSION}${_CLR_GREEN}, RPA channel:${_CLR_YELLOW}${_RPA_CHANNEL}${_CLR_GREEN}, MQ channel:${_CLR_YELLOW}${_MQ_CHANNEL}${_CLR_GREEN}') [managed: ${_CLR_YELLOW}${_RPA_MANAGED}${_CLR_GREEN}] in namespace '${_CLR_YELLOW}${_RPA_NAMESPACE}${_CLR_GREEN}', please wait..."

installRpaStandalone
