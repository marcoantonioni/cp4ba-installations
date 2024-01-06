# cp4ba-installations


...description of contents TBD

... preprequisiti linux box, tools

... prerequisiti cluster OCP

... tempi medi per worker 16cpu 

---
**DISCLAIMER**


<u>The entire contents of this repository are not intended for production environments.</u>

The main purpose is self-education and for test or demo environments.
No form of support or warranty is applicable.

Only the <b>.sh</b> scripts and <b>.properties</b> configuration files are released in open source mode according to https://opensource.org/license/mit/

<i>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge , publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.</i>

The configurations for CR .yaml deployment 

    apiVersion: icp4a.ibm.com/v1

    kind: ICP4ACluster

are the property of IBM as per the official wording:

Licensed Materials - Property of IBM

(C) Copyright IBM Corp. 2022, 2023. All Rights Reserved.

US Government Users Restricted Rights - Use, duplication or
disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

---


## TBD

- creare file configurazione template base
  partire da baw e aggiungere 
    -# Process Federation Portal
    export CP4BA_INST_PFS=true
    export CP4BA_INST_PFS_NAME="pfs-demo"
    export CP4BA_INST_PFS_NAMESPACE="${CP4BA_INST_NAMESPACE}"
    export CP4BA_INST_PFS_STORAGE_CLASS="${CP4BA_INST_SC_FILE}"
    export CP4BA_INST_PFS_APP_VER="${CP4BA_INST_APPVER}"
    export CP4BA_INST_PFS_ADMINUSER="${CP4BA_INST_PAKBA_ADMIN_USER}"
    export CP4BA_INST_PFS_TOOLS_FOLDER="../../cp4ba-process-federation-server"


- aggiungere versione file configurazione
  verifica versione script con versione file configurazione in uso per deployment

- studiare configurazione automatica per url/context del PFS
    pre deploy oppure nel loop wait cfg aggiungere test su PFS e lettura dapo con patch dei BAW che hanno cfg federazione
    patch CR se pfs non pronto

    modificare script di deploy
      se ...BAW_FEDERATE=true e presente e ready PFS
        legge da PFS hostname e ctx
        patch della CR sezione BAW con sezione
          process_federation_server:
            hostname: "cpd-cp4ba-test1.apps.658a741397f3750011a5d9d4.cloud.techzone.ibm.com"
            context_root_prefix: "/pfs"

          https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers

- sviluppo app demo case-solution e workflow
- deploy automatizzato applicazione case solution
- deploy automatizzato applicazione bpm

- verificare se il navigator è sempre mandatorio (serve db)

- disattivare e rimuovere app Hiring (aprire case per mancanza flag forzatura in ProcessAdmin)

      {
        "container_name": "Hiring Sample",
        "container": "HSS",
        "id": "2066.9ab0d0c6-d92c-4355-9ed5-d8a05acdc4b0",
        "description": "Hiring Sample",
        "creation_date": "2024-01-04T13:27:34z",
        "creator_user_id": "2048.1",
        "creator_user_name": "Automation System Account",
        "toolkit": false,
        "archived": false
      },

      cercare api per ottenere versione: RHSV180

      -- deactivate
      curl -X 'POST' \
        'https://cpd-cp4ba-test1-baw.apps.65800a760763df0011005ecb.cloud.techzone.ibm.com/baw-baw1/ops/std/bpm/containers/HSS/versions/RHSV180/deactivate?force=true&suspend_bpd_instances=true' \
        -H 'accept: application/json' \
        -H 'BPMCSRFToken: eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE3MDQzODg2NzIsInN1YiI6ImNwNGFkbWluIn0.6_y3Hq6P_4Dvls35s8oPwXeGmi_OghqW1ocRb9z-g9A' \
        -d ''

      -- delete
      curl -X 'DELETE' \
        'https://cpd-cp4ba-test1-baw.apps.65800a760763df0011005ecb.cloud.techzone.ibm.com/baw-baw1/ops/std/bpm/containers/HSS/versions?versions=RHSV180&force=true' \
        -H 'accept: application/json' \
        -H 'BPMCSRFToken: eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE3MDQzODg2NzIsInN1YiI6ImNwNGFkbWluIn0.6_y3Hq6P_4Dvls35s8oPwXeGmi_OghqW1ocRb9z-g9A'


- navigator desktop quando più di un baw

- studiare per Task prioritization, Workforce Insights
    eseguito test: ??? JMS, Business Automation Workflow
  https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=services-preparing-storage

- my-postgres-1-for-cp4ba-superuser per pw db
	
- configurazione AE
  secret per AE
  aggiunta sezioni in CR templates: AE
  /home/marco/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/patterns


- fase di prevalidazione su tag cr
    content e bpmonly
    nomi db
    parametri mandatori
    pfs e elasticsearch

- TEST - verifica configurazione CR base se LDAP e DB preesistenti


## Asks to experts

- icn_repos / icn_desktop, devono essere intesi come OS documentali come semplice FNET ? ?

- tablespaces 
    sono necessari anche per AE e i vari OS aggiuntivi ?


## Memos of command

```
su - user1

_INST_ENV=AUTO-1
PS1="[\u@ \033[0;31m(${_INST_ENV})\033[0m \W]> "

cd ~/cp4ba-projects/cp4ba-installations/scripts


#----------------------------
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
CONFIG_FILE=../configs/env1.properties
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -p ${caseManagerScriptsFolder}





#------------------------------
CONFIG_FILE=../configs/env1-baw.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-double.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-bpmonly.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0



#------------------------------
# Generate YAML & SQL only

# generate only
CONFIG_FILE=../configs/env1-baw.properties
time ./cp4ba-deploy-env.sh -c ${CONFIG_FILE} -g

CONFIG_FILE=../configs/env1-baw.properties
LDAP_CONFIG_FILE=../configs/_cfg-production-ldap-domain.properties
time ./cp4ba-deploy-env.sh -c ${CONFIG_FILE} -l ${LDAP_CONFIG_FILE} -g

#------------------------------
# TEST INSTALLER
CONFIG_FILE=../configs/env-test-installer.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0



#=======================================================================
# DEMO PFS WFPS BAW


#------------------------------
CONFIG_FILE=../configs/env1-baw-demo-wfps-baw.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0

oc logs -f -n cp4ba-wfps-baw-pfs-demo -c operator $(oc get pods -n cp4ba-wfps-baw-pfs-demo | grep cp4a-operator- | awk '{print $1}') | grep "FAIL"

oc logs -f -n cp4ba-wfps-baw-pfs-demo $(oc get pods -n cp4ba-wfps-baw-pfs-demo | grep pfs-operator- | awk '{print $1}') | grep -i "FAIL"

# !!!! rivedere copia configurazione con ns allineati per demo
# dopo deploy wfps
./pfs-show-federated.sh -c ../configs/pfs1.properties

#--------------------------
cd /home/marco/cp4ba-projects/cp4ba-wfps-utils/scripts
time ./wfps-install-application.sh -c ./configs/wfps-pfs-demo.properties -a ../apps/SimpleDemoWfPS.zip



#-----------------------------

#CONFIG_FILE=../configs/env1-baw.properties
#time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0

#------------------------------
TNS=cp4ba-...
oc logs -f -n $TNS -c operator $(oc get pods -n $TNS | grep cp4a-operator- | awk '{print $1}') | grep "FAIL"
_operator_failures=$(oc logs -n $TNS -c operator $(oc get pods -n $TNS | grep cp4a-operator- | awk '{print $1}') | grep "FAIL" | wc -l)

oc get pvc -A | grep Pending | grep -Ev "ibm-zen-cs-mongo-backup|ibm-zen-objectstore-backup-pvc"
_NUM_PENDING_PVC=$(oc get pvc -A | grep Pending | grep -Ev "ibm-zen-cs-mongo-backup|ibm-zen-objectstore-backup-pvc" | wc -l)


cd cp4ba-utilities/remove-cp4ba/
./cp4ba-remove-namespace.sh -n cp4ba-test1-baw && ./cp4ba-remove-namespace.sh -n cp4ba-test1-baw-double && ./cp4ba-remove-namespace.sh -n cp4ba-test1-baw-bpm-only

#------------------------------
TNS=cp4ba-test-db
oc new-project ${TNS}
# install operator 

./cp4ba-install-db.sh -c ../configs/env1-test-db.properties
./cp4ba-create-databases.sh -c ../configs/env1-test-db.properties


#source ../configs/_cfg-production-ldap-domain.properties
#source ../configs/_cfg-production-idp.properties
#source ../configs/env1.properties
#../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ../configs/_cfg-production-ldap-domain.properties
#./cp4ba-install-db.sh -c ../configs/env1.properties
#./cp4ba-create-secrets.sh -c ../configs/env1.properties
#envsubst < ../templates/cp4ba-cr-ref.yaml > ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#./cp4ba-create-pvc.sh -c ../configs/env1.properties
#oc apply -n ${CP4BA_INST_NAMESPACE} --dry-run=server -f ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#
#oc apply -n ${CP4BA_INST_NAMESPACE} -f ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#
#./cp4ba-create-secrets.sh -c ../configs/env1.properties -w
#./cp4ba-create-databases.sh -c ../configs/env1.properties -w



oc logs -n cp4ba-wfps-baw-pfs-demo $(oc get pods -n cp4ba-wfps-baw-pfs-demo | grep case-init-job | awk '{print $1}') | grep "INFO: Configuration Completed"


https://cpd-cp4ba-test1-baw.apps.65800a760763df0011005ecb.cloud.techzone.ibm.com/baw-baw1/ops/docs?tags=

```
# Notes

## Local DB access

```
_HOST_PORT=5432
_DB_CR_NAME="my-postgres-1-for-cp4ba"
_INST_ENV="wfps-baw-pfs-demo" 
_DB_NAME="${_INST_ENV//-/_}_baw_1"
_DB_USER="bawdocs"
TNS="cp4ba-wfps-baw-pfs-demo"

echo "Forwarding local port ${_HOST_PORT} to ${_DB_CR_NAME}-1 pod..."
PSQL_POD_NAME=$(oc get pod -n ${TNS} | grep ${_DB_CR_NAME}-1 | grep Running | grep -v deploy | grep -v hook | awk '{print $1}')
if [ ! -z ${PSQL_POD_NAME} ]; then 
  oc port-forward -n ${TNS} ${PSQL_POD_NAME} ${_HOST_PORT}:${_HOST_PORT}; 
fi 

#superuser ???
DB_USER=$(oc get secret -n ${TNS} ${_DB_CR_NAME}-app -o jsonpath='{.data.username}' | base64 -d)
DB_PASSWORD=$(oc get secret -n ${TNS} ${_DB_CR_NAME}-app -o jsonpath='{.data.password}' | base64 -d)
DB_PGPASS=$(oc get secret -n ${TNS} ${_DB_CR_NAME}-app -o jsonpath='{.data.pgpass}' | base64 -d)
_PASSWD=$(echo $DB_PGPASS | sed 's/\(.*\):/\1REMOVEBEFORE/' | sed 's/.*REMOVEBEFORE//g')
echo $DB_USER / $DB_PASSWORD / $DB_PGPASS

export PGPASSFILE='/home/'$USER'/.pgpass'
echo "${DB_PGPASS}" | sed 's/'${_DB_CR_NAME}'-rw:/localhost:/g' | sed 's/fake/'${_DB_NAME}'/g' | sed 's/:postgres:/:'${_DB_USER}':/g' | sed 's/'${_PASSWD}'/dem0s/g' >> ${PGPASSFILE}
chmod 0600 ${PGPASSFILE}

psql -h localhost -U ${_DB_USER} -d ${_DB_NAME}

# when in psql

  -- list databases
  \l

  -- connect to
  \c <your-db-name>

  -- list schemas
  \dn+ 

  -- list tables for baw db (schema bawadmin)
  \dt+ bawadmin.*

  -- list tablespaces
  select spcname FROM pg_tablespace;

  -- exit from psql
  \q

```

## other

- AE
  https://cpd-cp4ba-test1.apps.656d742d396eca001136ea72.cloud.techzone.ibm.com/ae-workspace1/v2/applications

# References

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-capability-patterns-production-deployments

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=bawraws-creating-required-databases-secrets-without-running-provided-scripts
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-pattern-configuration
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scp-shared-configuration
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/19.0.x?topic=piban-creating-volumes-folders-deployment-kubernetes
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scripts-creating-required-databases-in-postgresql
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=services-preparing-storage
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-runtime-workstream-services
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-authoring
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-initialization
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers

Navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=foundation-configuring-navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=cpbaf-business-automation-navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=navigator-creating-databases-without-running-provided-scripts
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=troubleshooting-navigator-initialization (pod name: icp4adeploy-navigator-deploy...)

Utilities
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=resource-validating-yaml-in-your-custom-file


https://www.ibm.com/docs/en/filenet-p8-platform/5.5.12?topic=vtpiicd-creating-postgresql-database-table-space-content-platform-engine-gcd
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=cfcmdswrps-creating-secrets-protect-sensitive-filenet-content-manager-configuration-data


BASTUDIO
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=foundation-configuring-business-automation-studio

PFS
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment



# misc
```
folder: /cert-kubernetes/descriptors/patterns


#-------------------------------
#_MAX_CHECKS=10
#_checks=0
#checkSecrets () {
#  _FOUND=$(oc get secret --no-headers -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAW_1_DB_SECRET} 2>/dev/null | wc -l)
#  if [[ "${_FOUND}" = "0" ]] && [[ $_checks -lt $_MAX_CHECKS ]]; then
#    ((_checks=_checks+1))
#    ./cp4ba-create-secrets.sh -c ${_CFG} -s -w -t 60
#    checkSecrets
#  fi
#}

cd /home/marco/cp4ba-projects/cp4ba-utilities/remove-cp4ba
./cp4ba-remove-namespace.sh -n cp4ba-test1-baw 2>/dev/null 1>/dev/null &
./cp4ba-remove-namespace.sh -n cp4ba-test1-baw-bis 2>/dev/null 1>/dev/null &
./cp4ba-remove-namespace.sh -n cp4ba-test1-baw-double 2>/dev/null 1>/dev/null &
./cp4ba-remove-namespace.sh -n cp4ba-test1-bpm-only 2>/dev/null 1>/dev/null &
./cp4ba-remove-namespace.sh -n cp4ba-test-installer 2>/dev/null 1>/dev/null &

```

