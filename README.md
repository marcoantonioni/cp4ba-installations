# cp4ba-installations

## Description of the contents of this repository

In this repository a series of procedures are available for the fully automated installation of IBM Cloud Pak for Business Automation environments in Openshift clusters.

The contents must be understood as examples of training on the topic of IT Operations. Obviously I am without any kind of support. Use them freely, modify them where necessary according to your needs.

This repository can be useful for professionals who create disposable environments dedicated to demonstrations/tests of the CP4BA product (IBMers, IBM Partners and Customers with active license to access to IBM Container Registry).


## Compatibility with CP4BA versions

These tools were developed starting from CP4BA v23.0.2 and Case Installation Manager v5.1.0.

The CRs in yaml format that you will find in the configuration examples may not be backwards compatible.

## .Necessary and optional tools for running scripts

A linux box (scripts are only available in the bash shell)

The Openshift CLI client

The 'jq' tool

The 'yq' tool (also available in IBM's CP4BA Case Package Manager)

The 'openssl' client tool (optional, used in conjunction with my other git repositories from the cp4ba-* family)

## Prerequisites for the Openshift cluster

The version of Openshift used must be among those supported by the CP4BA version

The cluster must offer dynamic storage classes for RWX and RWO (file & block) claims.

All examples use dynamic volume creation to support deployments.

## Skill prerequisites

A minimum knowledge of the bash shell.

Basic knowledge of the 'oc' commands (Openshift CLI) to log in to the cluster, to verify the presence of the prerequisites for the dynamic storage classes, to inspect the contents of the CRs for post-installation and final verification of correctness and functionality of what has been deployed.

## Repository structure

This repository contains four folders for this version described as follows:

```
.
├── configs
├── output
├── scripts
└── templates
```

### Folder: configs

Contains all configuration files for the available examples.

There are files with the '.properties' extension that guide the execution of the various shell scripts for the installation and configuration of the various components.

There is also a '.ldiff' file with an example of an authentication domain for an LDAP instance (details in the next sections).

There is also a configuration template file (env-template.properties) that you can use to define your scenarios.

There are examples for Production-type environments and examples for Starter-type environments (with attached authoring environment).

For Production environments there are currently examples for Foundation and Workflow deployments only.

### Folder: output

The 'output' folder is populated with some files created during the installation of the environments.

For each installation, the CR ICP4ACluster yaml file is created, enhanced with the parameters used for the installation (.properties), the sql file with the statements for the creation of the various databases to support the capabilities, a txt file containing the URLs of access to the various consoles of the deployed capabilities.

### Folder: scripts

```
./scripts/
├── cp4ba-create-databases.sh
├── cp4ba-create-pvc.sh
├── cp4ba-create-secrets.sh
├── cp4ba-deploy-env.sh
├── cp4ba-install-db.sh
├── cp4ba-install-operators.sh
└── cp4ba-one-shot-installation.sh
```
The 'scripts' folder contains a series of shell scripts dedicated to individual steps of the installation.
You will only use one.

Yes, it really is a 'one-shot' command with a couple of parameters, one of which is optional... I think we can talk about real automation ;)

The shell script we will use for installations is 'cp4ba-one-shot-installation.sh'.

With this command guided by one of your .properties files, in addition to the deployment of CP4BA capabilities, you can have a containerized PostgreSQL database to support the deployed capabilities and a containerized OpenLDAP server for the creation of your authentication domain.

### Folder: templates

The 'templates' folder contains a series of yaml files that respect the configuration structure of the CR ICP4Automation with the values area containing the '${..key..}' placeholders which will be replaced by the values of the properties file used for deployment .

```
apiVersion: icp4a.ibm.com/v1
kind: ICP4ACluster
metadata:
  name: ${CP4BA_INST_CR_NAME}
  namespace: ${CP4BA_INST_NAMESPACE}
  labels:
    app.kubernetes.io/instance: ibm-dba
...
```

These files can be further customized in compliance with the structure allowed by the CP4BA operators of the version in use.





## ... descrizione template .properties

## prerequisiti per la installazione

variabili env con key per creazione ibm-entitlement-key

## ... esempi di installazione

For the deployment of Process Federation Server and Workflow Process Service, refer to my other git repositories of the cp4ba-* family

### ... scenario WfPS, PFS, BAW

## ... tempi medi per worker 16cpu 

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

- check navigator desktop when more than one baw full

- add config version variable (must match with yaml template)
-- add runtime verification


# References

## Production Deployments
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-capability-patterns-production-deployments

## Databases - Postgres
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scripts-creating-required-databases-in-postgresql

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=services-preparing-storage

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=bawraws-creating-required-databases-secrets-without-running-provided-scripts

### Databases - Postgres - FNET
https://www.ibm.com/docs/en/filenet-p8-platform/5.5.12?topic=vtpiicd-creating-postgresql-database-table-space-content-platform-engine-gcd

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=cfcmdswrps-creating-secrets-protect-sensitive-filenet-content-manager-configuration-data

## Configuration parameters
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-pattern-configuration

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-initialization

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=scp-shared-configuration

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/19.0.x?topic=piban-creating-volumes-folders-deployment-kubernetes

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-runtime-workstream-services

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-workflow-authoring

## Federate capabilities
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployments-installing-cp4ba-process-federation-server-production-deployment

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-federating-business-automation-workflow-containers

### Administering and operating IBM Process Federation Server Containers
https://github.com/icp4a/process-federation-server-containers

## Navigator
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=foundation-configuring-navigator

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=cpbaf-business-automation-navigator

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=parameters-business-automation-navigator

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=navigator-creating-databases-without-running-provided-scripts

https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=troubleshooting-navigator-initialization 

## Utilities
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=resource-validating-yaml-in-your-custom-file

## BAStudio
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=foundation-configuring-business-automation-studio


## Detailed system requirements for a specific product

https://www.ibm.com/software/reports/compatibility/clarity/softwareReqsForProduct.html

## Tools

### Openshift CLI
[https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html](https://docs.openshift.com/container-platform/4.14/cli_reference/openshift_cli/getting-started-cli.html)

### JQ
[https://jqlang.github.io/jq](https://jqlang.github.io/jq)

### YQ
[https://github.com/mikefarah/yq](https://github.com/mikefarah/yq)
You may find a portable version of 'yq' in folder './scripts/helper/yq/' of CP4BA Case Installation tool.

### Openssl
[https://www.openssl.org/](https://www.openssl.org/)

### Home of CP4BA Case Installation tool
https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-automation

## CP4BA Silent installation
[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=o2isdbrs-option-2b-setting-up-cluster-in-silent-mode](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=o2isdbrs-option-2b-setting-up-cluster-in-silent-mode)

[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=reference-environment-variables-silent-mode-installation](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=reference-environment-variables-silent-mode-installation)


