# cp4ba-installations

## TBD
- onboarding utenze a fine installazione
- creazione pvc da riveder con configurazione automatica del navigator
- aggiunta sezioni in CR templates

cd .../cp4ba-installations/scripts

caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"

1. crea ns e installa operatori
1.1 ./cp4ba-install-operators.sh -c ../configs/env1.properties -s ${caseManagerScriptsFolder}

2. source config files (strict order)
2.1 source ../configs/_cfg-production-ldap-domain.properties
2.2 source ../configs/_cfg-production-idp.properties
2.3 source ../configs/env1.properties
3. installa ldap (verificare LDAP_LDIF_NAME nel file di cfg)
3.1 ../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ../configs/_cfg-production-ldap-domain.properties
4. installa db
4.1 ./cp4ba-install-db.sh -c ../configs/env1.properties
5. crea secrets
5.1 ./cp4ba-create-secrets-pre.sh -c ../configs/env1.properties
6. genera CR
6.1 envsubst < ../notes/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
6.2 more ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
7. crea pvc
7.1 ./cp4ba-create-pvc.sh -c ../configs/env1.properties
8. test
8.1 oc apply -n ${CP4BA_INST_NAMESPACE} --dry-run=server -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
9. deploy
9.1 oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
10 rerun secrets creation if errors
10.1 ./cp4ba-create-secrets-pre.sh -c ../configs/env1.properties
11. creazione db
11. da pod postgres poi creare script
12. onboard users from LDAP
12.1 ../../cp4ba-idp-ldap/scripts/onboard-users.sh -p ../configs/_cfg-production-idp.properties  -o add -s


#---------------
```

# duration: +/- 9 minutes (TechZone - 16cpu x node)
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-install-operators.sh -c ../configs/env1.properties -s ${caseManagerScriptsFolder}

# duration: +/- ?? minutes
time ./cp4ba-deploy-env.sh -c ../configs/env1.properties -s ../configs/db-statements.sql -l ../configs/_cfg-production-ldap-domain.properties -i ../configs/_cfg-production-idp.properties

#------------------------------
CONFIG_FILE=../configs/env1.properties
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -s ../notes/db-statements-ref-no-case.sql -l ../configs/_cfg-production-ldap-domain.properties -i ../configs/_cfg-production-idp.properties -p ${caseManagerScriptsFolder}

#------------------------------
CONFIG_FILE=../configs/env2.properties
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -s ../notes/db-statements-ref-no-case.sql -l ../configs/_cfg-production-ldap-domain.properties -i ../configs/_cfg-production-idp.properties -p ${caseManagerScriptsFolder}

#------------------------------
CONFIG_FILE=../configs/env3.properties
caseManagerScriptsFolder="/home/$USER/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
time ./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -s ../notes/db-statements-ref-no-case.sql -l ../configs/_cfg-production-ldap-domain.properties -i ../configs/_cfg-production-idp.properties -p ${caseManagerScriptsFolder}


#source ../configs/_cfg-production-ldap-domain.properties
#source ../configs/_cfg-production-idp.properties
#source ../configs/env1.properties
#../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ../configs/_cfg-production-ldap-domain.properties
#./cp4ba-install-db.sh -c ../configs/env1.properties
#./cp4ba-create-secrets.sh -c ../configs/env1.properties
#envsubst < ../notes/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#./cp4ba-create-pvc.sh -c ../configs/env1.properties
#oc apply -n ${CP4BA_INST_NAMESPACE} --dry-run=server -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#
#oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
#
#./cp4ba-create-secrets.sh -c ../configs/env1.properties -w
#./cp4ba-create-databases.sh -c ../configs/env1.properties -s ../configs/db-statements.sql -w

```
# Notes

- icp4adeploy-baw1-baw-db-init-job 
  create tables in: test1_baw_1=# \dt+ postgres.*

- icp4adeploy-workspace1-aae-ae-db-job
  import toolkits AE

  test1icn=# \dt+ icndb.*

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

