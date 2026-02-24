#!/bin/bash

_me=$(basename "$0")

_CFG=""

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
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit 1
fi

source ${_CFG}

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

#--------------------------------
# Cluster EDB (deprecated)
#--------------------------------
_deployDBClusterEDB () {

  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    resourceExist $2 cluster $1
    if [ $? -eq 1 ]; then
      oc delete cluster -n $2 $1 2>/dev/null 1>/dev/null
    fi

    # v25
    #    icr.io/cpopen/edb/postgresql:14.18-5.16.0@sha256:8ceef1ac05972ab29b026fab3fab741a3c905f17773feee2b34f513e444f0fda

    # vPREV
    #    icr.io/cpopen/edb/postgresql:13.10-4.14.0@sha256:0064d1e77e2f7964d562c5538f0cb3a63058d55e6ff998eb361c03e0ef7a96dd

    if [[ -z "${CP4BA_INST_DB_IMAGE}" ]]; then

      # check CP4BA version
      case "${CP4BA_INST_APPVER}" in
          25*)
                  _imageName="icr.io/cpopen/edb/postgresql:14.18-5.16.0@sha256:8ceef1ac05972ab29b026fab3fab741a3c905f17773feee2b34f513e444f0fda";;
          *)
                  _imageName="icr.io/cpopen/edb/postgresql:13.10-4.14.0@sha256:0064d1e77e2f7964d562c5538f0cb3a63058d55e6ff998eb361c03e0ef7a96dd";;
      esac

    else
      _imageName="${CP4BA_INST_DB_IMAGE}"
    fi

    echo "Deploying cluster postgresql.k8s.enterprisedb.io name '$1'"
    echo "  CP4BA '${CP4BA_INST_APPVER}' use image name: "${_imageName}

    _PG_CLUSTER_CR_TMP="/tmp/cp4ba-pg-cluster-$USER-$RANDOM"

cat <<EOF > ${_PG_CLUSTER_CR_TMP}
apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: $1
  namespace: $2
spec:
  logLevel: info
  startDelay: 30
  stopDelay: 30
  resources:
    limits:
      cpu: "${CP4BA_INST_DB_LIMITS_CPU}"
      memory: "${CP4BA_INST_DB_LIMITS_MEMORY}"
    requests:
      cpu: "${CP4BA_INST_DB_REQS_CPU}"
      memory: "${CP4BA_INST_DB_REQS_MEMORY}"
  imageName: >-
    ${_imageName}
  enableSuperuserAccess: true
  bootstrap:
    initdb:
      database: ${CP4BA_INST_DB_FAKE}
      encoding: UTF8
      localeCType: C
      localeCollate: C
      owner: ${CP4BA_INST_DB_OWNER}
  postgresql:
    parameters:
      log_truncate_on_rotation: 'false'
      archive_mode: 'on'
      log_filename: postgres
      archive_timeout: 5min
      max_replication_slots: '32'
      log_rotation_size: '0'
      work_mem: 20MB
      shared_preload_libraries: ''
      logging_collector: 'on'
      wal_receiver_timeout: 5s
      log_directory: /controller/log
      log_destination: csvlog
      wal_sender_timeout: 5s
      max_worker_processes: '32'
      max_parallel_workers: '32'
      log_rotation_age: '0'
      shared_buffers: 512MB
      max_prepared_transactions: '100'
      shared_memory_type: mmap
      dynamic_shared_memory_type: posix
      wal_keep_size: 512MB
    pg_hba:
      - host all all 0.0.0.0/0 md5
    syncReplicaElectionConstraint:
      enabled: false
  minSyncReplicas: 0
  maxSyncReplicas: 0
  postgresGID: 26
  postgresUID: 26
  primaryUpdateMethod: switchover
  switchoverDelay: 40000000
  storage:
    resizeInUseVolumes: true
    size: "${CP4BA_INST_DB_STORAGE_SIZE}"
    storageClass: ${CP4BA_INST_SC_FILE}
  primaryUpdateStrategy: unsupervised
  instances: 1
EOF

    # - loop 
    while [ true ]
    do
      # apply CR
      oc apply -n $2 -f ${_PG_CLUSTER_CR_TMP} 2>/dev/null 1>/dev/null
      if [ $? -gt 0 ]; then
        # echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
        # echo -e "${_CLR_RED}[✗] Error deploying Postgres CR '${_CLR_YELLOW}${_PG_CLUSTER_CR_TMP}${_CLR_RED}'${_CLR_NC}, retry now..."      
        sleep 10
      else
        # -- verify CR existence
        resourceExist $2 "clusters.postgresql.k8s.enterprisedb.io" $1
        
        # -- if OK end loop
        if [ $? -eq 1 ]; then
          echo "Deployed cluster postgresql.k8s.enterprisedb.io name '$1'"
          break
        else
          sleep 1
        fi
      fi
    done

    rm ${_PG_CLUSTER_CR_TMP} 2>/dev/null 1>/dev/null

  else
    echo -e "${_CLR_RED}[✗] ERROR: _deployDBClusterEDB name or namespace empty${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------
# Postgresql (StatefulSet)
#--------------------------------

#--------------------------------
# Postgres instance for all databases but ZEN,BTS,IM

_deployPostgresNoSSL () {

  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    resourceExist $2 statefulsets.apps $1
    if [ $? -eq 1 ]; then
      oc delete statefulsets.apps -n $2 $1 2>/dev/null 1>/dev/null
    fi

    _imageName="${CP4BA_INST_DB_OSS_IMAGE}"

    echo "Deploying statefulset name '$1'"
    echo "  CP4BA '${CP4BA_INST_APPVER}' use image name: "${_imageName}

    _PG_SS_CR_TMP="/tmp/cp4ba-pg-statefulset-$USER-$RANDOM"

    _PG_CONFIG_CM=my-postgresql-config    
    _PG_CONF_FOLDER=/tmp/cp4ba-pg-conf-folder-$USER-$RANDOM
    mkdir -p ${_PG_CONF_FOLDER} 2>/dev/null 1>/dev/null

    # copiare template .conf
    if [[ -f "${CP4BA_INST_DB_POSTGRES_CONF_TEMPLATE}"  ]]; then
      cp ${CP4BA_INST_DB_POSTGRES_CONF_TEMPLATE} ${_PG_CONF_FOLDER}/
    else
      echo -e "${_CLR_RED}[✗] ERROR: _deployPostgresNoSSL template not found: ${CP4BA_INST_DB_POSTGRES_CONF_TEMPLATE}${_CLR_NC}"
      exit 1
    fi

    # create CM for PG configuration files
    oc delete configmap -n ${CP4BA_INST_NAMESPACE} ${_PG_CONFIG_CM} 2>/dev/null 1>/dev/null
    oc create configmap -n ${CP4BA_INST_NAMESPACE} ${_PG_CONFIG_CM} --from-file=${_PG_CONF_FOLDER}/ 2>/dev/null 1>/dev/null


cat <<EOF > ${_PG_SS_CR_TMP}
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: $1
  namespace: $2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $1
  serviceName: $1
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain
  volumeClaimTemplates:
    - kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: $1
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: ${CP4BA_INST_DB_STORAGE_SIZE}
        storageClassName: ${CP4BA_SC_NAME}
        volumeMode: Filesystem
      status:
        phase: Pending
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: $1
    spec:
      # 20260223
      volumes:
        - name: config-vol
          configMap:
            name: ${_PG_CONFIG_CM}
            defaultMode: 0640
        - name: data-volume
          emptyDir: {}

      containers:
        - name: postgres
          image: '${_imageName}'
          ports:
            - name: postgres
              containerPort: 5432
              protocol: TCP
          env:
            - name: POSTGRES_PASSWORD
              value: "${CP4BA_INST_DB_OSS_ADMIN_PASSWORD}"
          resources:
            limits:
              cpu: "${CP4BA_INST_DB_LIMITS_CPU}"
              memory: "${CP4BA_INST_DB_LIMITS_MEMORY}"
            requests:
              cpu: "${CP4BA_INST_DB_REQS_CPU}"
              memory: "${CP4BA_INST_DB_REQS_MEMORY}"
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent

          #20260223
          volumeMounts:
            - name: config-vol
              mountPath: /etc/postgresql/
            - name: data-volume
              mountPath: /etc/postgresql-data
                  
          args:
            - -c
            - config_file=/etc/postgresql/postgresql_nossl.conf

      restartPolicy: Always
      terminationGracePeriodSeconds: 10
      dnsPolicy: ClusterFirst
      serviceAccountName: ibm-cp4ba-anyuid
      serviceAccount: ibm-cp4ba-anyuid
      securityContext:
        runAsUser: 999
        runAsGroup: 999   
        fsGroup: 999
      schedulerName: default-scheduler
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
---
kind: Service
apiVersion: v1
metadata:
  name: $1-rw
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
---
kind: Service
apiVersion: v1
metadata:
  name: $1-ro
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
---
kind: Service
apiVersion: v1
metadata:
  name: $1-r
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
EOF


    # - loop 
    while [ true ]
    do
      # apply CR
      oc apply -n $2 -f ${_PG_SS_CR_TMP} 2>/dev/null 1>/dev/null
      if [ $? -gt 0 ]; then
        # echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
        # echo -e "${_CLR_RED}[✗] Error deploying Postgres CR '${_CLR_YELLOW}${_PG_SS_CR_TMP}${_CLR_RED}'${_CLR_NC}, retry now..."      
        sleep 10
      else
        # -- verify CR existence
        resourceExist $2 "statefulsets.apps" $1
        
        # -- if OK end loop
        if [ $? -eq 1 ]; then
          # oc adm policy add-scc-to-user anyuid -z postgres-anyuid -n $2 2>/dev/null 1>/dev/null

          echo "Deployed statefulsets.apps name '$1'"
          break
        else
          sleep 1
        fi
      fi
    done

    rm ${_PG_SS_CR_TMP} 2>/dev/null 1>/dev/null

  else
    echo -e "${_CLR_RED}[✗] ERROR: _deployPostgresNoSSL name or namespace empty${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------
# Postgresql (StatefulSet)
#--------------------------------

#--------------------------------
# Postgres instance with SSL enabled (ZEN,BTS,IM external databases)

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

_deployPostgresSSL () {

  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    resourceExist $2 statefulsets.apps $1
    if [ $? -eq 1 ]; then
      oc delete statefulsets.apps -n $2 $1 2>/dev/null 1>/dev/null
    fi

    _imageName="${CP4BA_INST_DB_OSS_IMAGE}"

    echo "Deploying SSL statefulset name '$1'"
    echo "  CP4BA '${CP4BA_INST_APPVER}' use image name: "${_imageName}

    _PG_SS_CR_TMP="/tmp/cp4ba-pg-statefulset-$USER-$RANDOM"


    _PG_CONFIG_CM=my-postgresql-config-ssl
    _PG_SECRETS=my-postgresql-secrets
    
    _PG_CONF_FOLDER=/tmp/cp4ba-pg-conf-folder-$USER-$RANDOM
    _PG_SECRETS_FOLDER=/tmp/cp4ba-pg-secrets-folder-$USER-$RANDOM

    mkdir -p ${_PG_CONF_FOLDER} 2>/dev/null 1>/dev/null
    mkdir -p ${_PG_SECRETS_FOLDER} 2>/dev/null 1>/dev/null

    _PG_CONF_FILE=${_PG_CONF_FOLDER}/postgresql_nossl.conf
    _PG_CONF_FILE_SSL=${_PG_CONF_FOLDER}/postgresql.conf
    _PG_HBA_CONF_FILE_TMP=${_PG_CONF_FOLDER}/pg_hba.conf.tmp
    _PG_HBA_CONF_FILE=${_PG_CONF_FOLDER}/pg_hba.conf

    # copiare template .conf
    if [[ -f "${CP4BA_INST_DB_POSTGRES_CONF_SSL_TEMPLATE}"  ]]; then
      cp ${CP4BA_INST_DB_POSTGRES_CONF_SSL_TEMPLATE} ${_PG_CONF_FOLDER}/ 2>/dev/null 1>/dev/null
    else
      echo -e "${_CLR_RED}[✗] ERROR: _deployPostgresSSL template not found: ${CP4BA_INST_DB_POSTGRES_CONF_SSL_TEMPLATE}${_CLR_NC}"
      exit 1
    fi
    if [[ -f "${CP4BA_INST_DB_POSTGRES_CONF_PGHBA_TEMPLATE}"  ]]; then
      cp ${CP4BA_INST_DB_POSTGRES_CONF_PGHBA_TEMPLATE} ${_PG_HBA_CONF_FILE_TMP} 2>/dev/null 1>/dev/null
    else
      echo -e "${_CLR_RED}[✗] ERROR: _deployPostgresSSL template not found: ${CP4BA_INST_DB_POSTGRES_CONF_PGHBA_TEMPLATE}${_CLR_NC}"
      exit 1
    fi

    cat ${_PG_HBA_CONF_FILE_TMP} | sed "s/host all all all scram-sha-256/host all all all trust/g" > ${_PG_HBA_CONF_FILE}

    echo "hostssl all all 127.0.0.1/32 password clientcert=verify-ca" >> ${_PG_HBA_CONF_FILE}
    echo "hostssl all all 127.0.0.1/32 cert clientcert=verify-full" >> ${_PG_HBA_CONF_FILE}

    # create CM for PG configuration files
    oc delete configmap -n ${CP4BA_INST_NAMESPACE} ${_PG_CONFIG_CM} 2>/dev/null 1>/dev/null
    oc create configmap -n ${CP4BA_INST_NAMESPACE} ${_PG_CONFIG_CM} --from-file=${_PG_CONF_FOLDER}/ 2>/dev/null 1>/dev/null

    _createDBCertificates ${_PG_SECRETS_FOLDER} ${CP4BA_INST_DB_1_SERVICE_SSL}

    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_PG_SECRETS} 2>/dev/null 1>/dev/null
    oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${_PG_SECRETS} --from-file=${_PG_SECRETS_FOLDER}/ 2>/dev/null 1>/dev/null

cat <<EOF > ${_PG_SS_CR_TMP}
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: $1
  namespace: $2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $1
  serviceName: $1
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain
  volumeClaimTemplates:
    - kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: $1
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: ${CP4BA_INST_DB_STORAGE_SIZE}
        storageClassName: ${CP4BA_SC_NAME}
        volumeMode: Filesystem
      status:
        phase: Pending
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: $1
    spec:
      volumes:
        - name: config-vol
          configMap:
            name: ${_PG_CONFIG_CM}
            defaultMode: 0640
        - name: secret-vol
          secret:
            secretName: ${_PG_SECRETS}
            defaultMode: 0640
        - name: data-volume
          emptyDir: {}

      containers:
        - name: postgres

          image: '${_imageName}'
          ports:
            - name: postgres
              containerPort: 5432
              protocol: TCP
          env:
            - name: POSTGRES_PASSWORD
              value: "${CP4BA_INST_DB_OSS_ADMIN_PASSWORD}"
          resources:
            limits:
              cpu: "${CP4BA_INST_DB_LIMITS_CPU}"
              memory: "${CP4BA_INST_DB_LIMITS_MEMORY}"
            requests:
              cpu: "${CP4BA_INST_DB_REQS_CPU}"
              memory: "${CP4BA_INST_DB_REQS_MEMORY}"
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          imagePullPolicy: IfNotPresent

          volumeMounts:
            - name: config-vol
              mountPath: /etc/postgresql/
            - name: secret-vol
              mountPath: /etc/postgresql-secrets
            - name: data-volume
              mountPath: /etc/postgresql-data
                  
          args:
            - -c
            - hba_file=/etc/postgresql/pg_hba.conf
            - -c
            - config_file=/etc/postgresql/postgresql_ssl.conf

      restartPolicy: Always
      terminationGracePeriodSeconds: 10
      dnsPolicy: ClusterFirst
      serviceAccountName: ibm-cp4ba-anyuid
      serviceAccount: ibm-cp4ba-anyuid
      securityContext:
        runAsUser: 999
        runAsGroup: 999   
        fsGroup: 999
      schedulerName: default-scheduler
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
---
kind: Service
apiVersion: v1
metadata:
  name: $1-rw
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
---
kind: Service
apiVersion: v1
metadata:
  name: $1-ro
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
---
kind: Service
apiVersion: v1
metadata:
  name: $1-r
  namespace: $2
spec:
  selector:
    app: $1
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
  ipFamilies:
    - IPv4
  internalTrafficPolicy: Cluster
  type: ClusterIP
EOF


    # - loop 
    while [ true ]
    do
      # apply CR
      oc apply -n $2 -f ${_PG_SS_CR_TMP} 2>/dev/null 1>/dev/null
      if [ $? -gt 0 ]; then
        sleep 10
      else
        # -- verify CR existence
        resourceExist $2 "statefulsets.apps" $1
        
        # -- if OK end loop
        if [ $? -eq 1 ]; then
          echo "Deployed statefulsets.apps name '$1'"
          break
        else
          sleep 1
        fi
      fi
    done

    # https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.x_cd?topic=management-configuring-external-postgresql-database-im

    _SEC_NAME="im-datastore-edb-secret"
    oc delete secret ${_SEC_NAME} -n "$2" >/dev/null 2>&1
    oc create secret generic ${_SEC_NAME} \
      --from-file=ca.crt="${_PG_SECRETS_FOLDER}/ca.cert" \
      --from-file=tls.crt="${_PG_SECRETS_FOLDER}/client.cert" \
      --from-file=tls.key="${_PG_SECRETS_FOLDER}/client.key" \
      --type=kubernetes.io/tls -n "$2" 2>/dev/null 1>/dev/null
    oc label secret ${_SEC_NAME} cp4ba.ibm.com/backup-type=mandatory -n "$2" 2>/dev/null 1>/dev/null

    _SEC_NAME="ibm-zen-metastore-edb-secret"
    oc delete secret ${_SEC_NAME} -n "$2" 2>/dev/null 1>/dev/null
    oc create secret generic -n "$2" ${_SEC_NAME} \
      --from-file=ca.crt="${_PG_SECRETS_FOLDER}/ca.cert"  \
      --from-file=tls.crt="${_PG_SECRETS_FOLDER}/client.cert"  \
      --from-file=tls.key="${_PG_SECRETS_FOLDER}/client.key"  \
      --type=kubernetes.io/tls 2>/dev/null 1>/dev/null
    oc label secret -n "$2" ${_SEC_NAME} cp4ba.ibm.com/backup-type=mandatory 2>/dev/null 1>/dev/null

    _SEC_NAME="bts-datastore-edb-secret"
    openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt \
      -in ${_PG_SECRETS_FOLDER}/client.key \
      -out ${_PG_SECRETS_FOLDER}/tls_key.pk8 2>/dev/null 1>/dev/null

    oc delete secret -n "$2" ${_SEC_NAME} 2>/dev/null 1>/dev/null
    oc create secret generic -n "$2" ${_SEC_NAME}  \
      --from-file=ca.crt="${_PG_SECRETS_FOLDER}/ca.cert"  \
      --from-file=tls.crt="${_PG_SECRETS_FOLDER}/client.cert"  \
      --from-file=tls.key="${_PG_SECRETS_FOLDER}/tls_key.pk8" 2>/dev/null 1>/dev/null
    oc label secret -n "$2" ${_SEC_NAME} cp4ba.ibm.com/backup-type=mandatory 2>/dev/null 1>/dev/null


    rm ${_PG_SS_CR_TMP} 2>/dev/null 1>/dev/null

    if [[ ! -z "${_PG_CONF_FOLDER}" ]]; then
      #echo "folder not removed: ${_PG_CONF_FOLDER}"
      rm -fr ${_PG_CONF_FOLDER} 2>/dev/null 1>/dev/null
    fi
    if [[ ! -z "${_PG_SECRETS_FOLDER}" ]]; then
      #echo "folder not removed: ${_PG_SECRETS_FOLDER}"
      rm -fr ${_PG_SECRETS_FOLDER} 2>/dev/null 1>/dev/null
    fi

  else
    echo -e "${_CLR_RED}[✗] ERROR: _deployPostgresSSL name or namespace empty${_CLR_NC}"
    exit 1
  fi
}

_deployDBCluster () {
  if [[ -z "${CP4BA_INST_DB_USE_EDB}" ]] || [[ "${CP4BA_INST_DB_USE_EDB}" = "true" ]]; then
    _deployDBClusterEDB "$1" "$2"
  else
    _deployPostgresNoSSL "$1" "$2"
    sleep 5
    _deployPostgresSSL "$3" "$2"
  fi

}

deployDBCluster() {
# $1: inst db
# $2: CR name
# $3: namespace
  if [[ "$1" = "true" ]]; then
    echo -e "${_CLR_GREEN}Deploying DB Cluster '${_CLR_YELLOW}$2${_CLR_GREEN}' in namespace '${_CLR_YELLOW}$3${_CLR_GREEN}'${_CLR_NC}"
    _deployDBCluster "$2" "$3" "$4"
  else
    echo -e "${_CLR_YELLOW}Skipping deployment of DB Cluster '${_CLR_GREEN}$1${_CLR_YELLOW}'${_CLR_NC}"
  fi
}

waitForClustersPostgresCRD () {
  echo "Wait for CR and Operator of 'clusters.postgresql.k8s.enterprisedb.io' (may take minutes)"

  if [ $(oc get crd clusters.postgresql.k8s.enterprisedb.io --no-headers 2> /dev/null | wc -l) -lt 1 ]; then
    while [ true ]
    do
      if [ $(oc get crd clusters.postgresql.k8s.enterprisedb.io --no-headers 2> /dev/null | wc -l) -lt 1 ]; then
        sleep 5
      else
        break
      fi
    done
  fi

  _READY_ITEMS=$(oc get crd clusters.postgresql.k8s.enterprisedb.io -o jsonpath='{.status.conditions}' | jq '.[] | select(.status=="True") ' | jq .status | wc -l)
  if [ $_READY_ITEMS -lt 2 ]; then
    while [ true ]
    do
      _READY_ITEMS=$(oc get crd clusters.postgresql.k8s.enterprisedb.io -o jsonpath='{.status.conditions}' | jq '.[] | select(.status=="True") ' | jq .status | wc -l)
      if [ $_READY_ITEMS -lt 2 ]; then
        sleep 5
        #echo -e -n "wait for CRD 'clusters.postgresql.k8s.enterprisedb.io' ready ... \033[0K\r"
      else
        break
      fi
    done
    #echo ""
  fi

  echo "Wait for pod 'postgresql-operator-controller-manager' creation ..."

  while [ true ]
  do
    sleep 5
    _PSQL_OCM_POD=$(oc get pod --no-headers -n ${CP4BA_INST_SUPPORT_NAMESPACE} 2>/dev/null | grep postgresql-operator-controller-manager | awk '{print $1}')
    if [[ ! -z "${_PSQL_OCM_POD}" ]]; then
      break
    fi
  done

  echo "Wait for pod 'postgresql-operator-controller-manager...' ready ..."
  START_SECONDS=$SECONDS

  while [ true ]
  do
    sleep 3
    _PSQL_OCM_POD=$(oc get pod --no-headers -n ${CP4BA_INST_SUPPORT_NAMESPACE} 2>/dev/null | grep postgresql-operator-controller-manager | awk '{print $1}')
    if [[ ! -z "${_PSQL_OCM_POD}" ]]; then
      _IS_READY=$(oc get pods -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${_PSQL_OCM_POD} | grep -m 1 "Running" | wc -l)
      if [ $_IS_READY -gt 0 ]; then
        echo "Pod 'postgresql-operator-controller-manager...' is ready"
        break
      else
        NOW_SECONDS=$SECONDS
        ELAPSED_SECONDS=$(( $NOW_SECONDS - $START_SECONDS ))
        TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
        TOT_MINUTES=$(( $(($ELAPSED_SECONDS / 60)) % 60))
        TOT_HOURS=$(( $(($ELAPSED_SECONDS / 3600)) % 24))

        echo -e -n "Pod 'postgresql-operator-controller-manager...' is NOT ready [[${_CLR_YELLOW}$TOT_HOURS${_CLR_GREEN}h:${_CLR_YELLOW}$TOT_MINUTES${_CLR_GREEN}m:${_CLR_YELLOW}$TOT_SECONDS${_CLR_GREEN}s]]\r"
        # echo -e -n "${_CLR_GREEN}Wait for Pod 'postgresql-operator-controller-manager...'\033[0K\r"
      fi
    fi
  done

}

deployDBClusters() {
# $1: namespace

  if [[ -z "${CP4BA_INST_DB_USE_EDB}" ]] || [[ "${CP4BA_INST_DB_USE_EDB}" = "true" ]]; then
    waitForClustersPostgresCRD
  fi

  i=1
  _IDX_END=$CP4BA_INST_DB_INSTANCES
  while [[ $i -le $_IDX_END ]]
  do
    _INST_DB_CR_NAME="CP4BA_INST_DB_"$i"_CR_NAME"
    _INST_DB_CR_NAME_SSL="CP4BA_INST_DB_"$i"_CR_NAME_SSL"
    if [[ ! -z "${!_INST_DB_CR_NAME}" ]]; then
      deployDBCluster ${CP4BA_INST_DB} ${!_INST_DB_CR_NAME} $1 ${!_INST_DB_CR_NAME_SSL}
    else
      echo -e "${_CLR_RED}ERROR, env var '${_CLR_GREEN}${_INST_DB_CR_NAME}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES and CP4BA_INST_DB_* values.${_CLR_NC}"
    fi
    ((i = i + 1))
  done  
}

#==================================

# echo -e "=============================================================="
echo -e "${_CLR_GREEN}Deploying '${_CLR_YELLOW}${CP4BA_INST_DB_INSTANCES}${_CLR_GREEN}' DB Clusters in namespace '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"

deployDBClusters ${CP4BA_INST_SUPPORT_NAMESPACE}

# test if operator present in ns when different namespaces
if [[ "${CP4BA_INST_SUPPORT_NAMESPACE}" != "${CP4BA_INST_NAMESPACE}" ]]; then
  if [ $(oc get -n ${CP4BA_INST_SUPPORT_NAMESPACE} csv --no-headers | grep "cloud-native-postgresql.v" | wc -l) -lt 1 ]; then
    echo -e "${_CLR_GREEN}Remember to install 'EDB Postgres for Kubernetes' operator in '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
  fi
fi
