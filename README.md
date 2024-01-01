# cp4ba-installations


...description of contents TBD

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

- se installato il cmgr dinamico create folder temporaneo con nome rnd e poi eliminare

- verificare appVersion di cmgr con quello della configurazione

- fase di prevalidazione su tag cr
    content e bpmonly
    nomi db
    parametri mandatori
    pfs e elasticsearch

- verificare navigator_configuration.icn_production_setting
  schema e tablespace

- se PFS aggiornare CR con
  sc_optional_components: 'elasticsearch'
	
- TEST - verifica configurazione CR base se LDAP e DB preesistenti

- configurazione AE
  secret per AE
  aggiunta sezioni in CR templates: AE
  /home/marco/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/patterns

- creare CR scenario federazione 'elasticsearch'
  se ...BAW_FEDERATE=true
    se presente PVS
      legge hostname e ctx
      patch della CR con sezione
        process_federation_server:
          hostname: "cpd-cp4ba-test1.apps.658a741397f3750011a5d9d4.cloud.techzone.ibm.com"
          context_root_prefix: "/pfs"

        https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers


## Asks to experts

- icn_repos / icn_desktop, add baw ?



## Memos of command

```
su - user1

_INST_ENV=AUTO-1
PS1="[\u@ \033[0;31m(${_INST_ENV})\033[0m \W]> "

cd ~/cp4ba-projects/cp4ba-installations/scripts


# duration: +/- 9 minutes (TechZone - 16cpu x node)
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-install-operators.sh -c ../configs/env1.properties -s ${caseManagerScriptsFolder}

# duration: +/- ?? minutes
time ./cp4ba-deploy-env.sh -c ../configs/env1.properties -l ../configs/_cfg-production-ldap-domain.properties -i ../configs/_cfg-production-idp.properties

#------------------------------
CONFIG_FILE=../configs/env1.properties
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -p ${caseManagerScriptsFolder}




#------------------------------
CONFIG_FILE=../configs/env1-baw-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-only-double.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-bpm-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0


#------------------------------
CONFIG_FILE=../configs/env1-wfps-bawonly.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0




#------------------------------
CONFIG_FILE=../configs/env2-baw-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env3-baw-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d ~/tmp-cmgr -v 5.1.0




#------------------------------
TNS=cp4ba-test1-baw-bpm-only
oc logs -f -n $TNS $(oc get pods -n $TNS | grep cp4a-operator- | awk '{print $1}') | grep "FAIL"

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

```
# Notes


- SELECT spcname FROM pg_tablespace;

- AE
  https://cpd-cp4ba-test1.apps.656d742d396eca001136ea72.cloud.techzone.ibm.com/ae-workspace1/v2/applications

# References

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=bawraws-creating-required-databases-secrets-without-running-provided-scripts
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-pattern-configuration
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/19.0.x?topic=piban-creating-volumes-folders-deployment-kubernetes
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scripts-creating-required-databases-in-postgresql
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-runtime-workstream-services
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-authoring
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-initialization

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



```

