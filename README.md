# cp4ba-installations

cd .../cp4ba-installations/scripts

caseManagerScriptsFolder="/home/marco/CP4BA/fixes/ibm-cp-automation-5.1.0/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"

1. crea ns e installa operatori
1.1 ./cp4ba-install-operators.sh -c ../configs/env1.properties -s ${caseManagerScriptsFolder}

2. source ../configs/env1.properties
3. installa ldap
3.1 aggiorna TNS e LDAP_LDIF_NAME nei file di cfg
3.2 ../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ../configs/_cfg-production-ldap-domain.properties
4. installa db
5. crea secrets
5.1 ./cp4ba-create-secrets-pre.sh -c ../configs/env1.properties
6. genera CR
6.1 envsubst < ../notes/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
6.2 more ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
7. test
7.1 oc apply -n ${CP4BA_INST_NAMESPACE} --dry-run=server -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
8. deploy
8.1 oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
9. onboard users from LDAP
