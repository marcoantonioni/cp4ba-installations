# cp4ba-installations

## TBD

- verificare navigator_configuration.icn_production_setting
  schema e tablespace

- rimuovere se PVC non necessitate (deploy-env.sh) 
    export CP4BA_INST_BAW_1_CFG_CONTENT=false
    export CP4BA_INST_BAW_1_CFG_CASE=false

- parametrizzare ../crs/cp4ba- e puntamenti a tools

- rimuovere checkSecrets

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
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-only-double.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-baw-bpm-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env1-wfps-bawonly.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0




#------------------------------
CONFIG_FILE=../configs/env2-baw-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0

#------------------------------
CONFIG_FILE=../configs/env3-baw-only.properties
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -d /tmp/test -v 5.1.0



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
#envsubst < ../templates/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#./cp4ba-create-pvc.sh -c ../configs/env1.properties
#oc apply -n ${CP4BA_INST_NAMESPACE} --dry-run=server -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#
#oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
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
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=navigator-creating-databases-without-running-provided-scripts
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-pattern-configuration
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/19.0.x?topic=piban-creating-volumes-folders-deployment-kubernetes
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scripts-creating-required-databases-in-postgresql
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-runtime-workstream-services
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=troubleshooting-navigator-initialization (pod name: icp4adeploy-navigator-deploy...)
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-authoring
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-initialization


https://www.ibm.com/docs/en/filenet-p8-platform/5.5.12?topic=vtpiicd-creating-postgresql-database-table-space-content-platform-engine-gcd
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=cfcmdswrps-creating-secrets-protect-sensitive-filenet-content-manager-configuration-data

# Create production CR
```
folder: /cert-kubernetes/descriptors/patterns




```

