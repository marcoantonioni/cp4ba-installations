# cp4ba-installations

## Description of the contents of this repository

In this repository a series of procedures are available for the fully automated installation of IBM Cloud Pak for Business Automation environments in Openshift clusters.

The contents must be understood as examples of training on the topic of CP4BA IT Operations. 

Obviously it is without any kind of support. Use them freely, modify them where necessary according to your needs.

This repository can be useful for professionals who create disposable environments dedicated to demonstrations/tests of the CP4BA product (IBMers, IBM Partners and Customers with active license to access to IBM Container Registry).

Please read the DISCLAIMER section carefully.

This repository was created to simplify my IBM CP4BA study and PoX activities.

Even if the installations as per the IBM user manual are relatively simple, they must always be contextualized in the various deployment combinations.

Some activities, such as the installation of the operators (the first step) are extremely simple, while the second activity can be complex and difficult to implement if you do not have a good knowledge of the capability you intend to deploy.

The scripts available in the CP4BA Case Manager package are extremely powerful and should be your primary choice for professional installations and configurations where for example the various databases and LDAP servers are external to the Openshift cluster, and the configurations are made in advance of the deployment phase of CR ICP4Automation.

The main objective of this repository is the further simplification and automation of the activities required by the official manuals.

## How this idea was born

One day I was bored with having to repeat the same sequence of activities often and I asked myself: "what if I automate everything?"

Thinking: Maybe I could use a simple properties file, a predefined template for various scenarios, and a single command that creates the configuration by merging the template and properties and then creating a containerized LDAP server, one or more containerized PostgreSQL instances and finally the deployment of CR ICP4Automation...and also execute the onboarding of LDAP users into Pak IDP.
Maybe to exaggerate even more I could also add a Portal Federation Server and configure the federation of the various BAW and WfPS instances defined in the template.

In the end I created this repository and since my role in IBM is that of presales I decided to make it public to help customers, business partners and also my IBM colleagues.

## Compatibility with CP4BA versions

These tools were developed starting from CP4BA v23.0.2 and Case Installation Manager v5.1.0.

The CRs in yaml format that you will find in the configuration examples may not be backwards compatible.

## Mandatory and optional tools for running scripts

A linux box (scripts are only available in the bash shell)

'oc' Openshift CLI client (mandatory)

'jq' tool (mandatory)

'yq' tool (mandatory, also available in IBM's CP4BA Case Package Manager)

'openssl' client tool (optional, used with my other git repositories from the cp4ba-* family, eg: for trusted certificate list configuration)

## Prerequisites for the Openshift cluster

The version of Openshift used must be among those supported by the CP4BA version

The cluster must offer dynamic storage classes for RWX and RWO (file & block) claims.

All examples use dynamic volume creation to support deployments.

## Skill prerequisites

A minimum knowledge of the bash shell.

Basic knowledge of the 'oc' commands (Openshift CLI) to log in to the cluster, to verify the presence of the prerequisites for the dynamic storage classes, to inspect the contents of the CRs for post-installation and final verification of correctness and functionality of what has been deployed.

## Repository structure

This repository contains four folders (for this version) described as follows:

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


## Description of file 'env-template.properties' (properties template, in folder 'configs')

The content of this file must be composed of: 
1) comment lines ```# this is a comment``` 
2) definition of ```export KEY=VALUE``` variables

The template is made up of various sections, some mandatory and others optional.
Some sections may have cardinality greater than one (for example multiple instances of BAW or other capability), in this case the variable nomenclature must follow the following rule, example:
```
export CP4BA_INST_BAW_1_NAME="baw1"
...
export CP4BA_INST_BAW_2_NAME="baw2"
```
The configuration scripts for the sections that can have cardinality greater than 1 perform a loop (up to a maximum of 10) to set the value in the various sections of the yaml template associated with the properties file.

You must replace all markers ```"<***To-Be-Replaced***>"``` with your values.

Pay attention to ```do not modify``` in comments.

Pay attention to the character length for all those variables that will be part of a K8S resource name (max limit 63 chars)

For example, the Service name ```icp4adeploy-baw-double-baw1-baw-service-headless``` (48 chars lenngth) is automatically composed by the CP4BA operators and is composed of:

```'cp4adeploy-baw-double'``` the name of the ICP4ACluster CR

```'baw1'``` the name of the BAW instance

```'baw-service-headless'``` suffix added by operator

### Sections in 'env-template.properties'

1. Main

* In this section you can define the name of the CR that will be created, the target namespace, the type of target platform (ROKS / OCP), the product version you intend to install, the CP4BA patterns and the optional components, the names of the available storage classes and the deployment administration user, the names of the folders of the other 'cp4ba-*' utilities supporting this repo and finally the thing that characterizes this configuration is the name of the '.yaml' file which must be used as a reference for generating the final valorized ICP4ACluster CR.

2. LDAP & IAM

* In this section the values for the installation and configuration of LDAP and IDP are defined.
* The boolean flag ```CP4BA_INST_LDAP``` indicates whether or not to install a local container for OpenLdap server.
* For an example see the file 'env1-baw.properties'.

3. DB

* This section defines the values for installing and configuring the databases to support the deployment.
* The boolean flag ```CP4BA_INST_DB``` indicates whether or not to install one or more local containers for PostgreSQL.
* The numerical value of ```CP4BA_INST_DB_INSTANCES``` indicates how many server instances must be installed, consequently the nomenclature of the sets of variables for each database must follow the rule
```
  CP4BA_INST_DB_1_CR_NAME="my-postgres-1-for-cp4ba"
  ...
  CP4BA_INST_DB_2_CR_NAME="my-postgres-2-for-cp4ba"
```
* For an example see the file 'env1-baw-double.properties'.

4. Capabilities (BAW,PFS,BAStudio, etc...)

* Various sets of variables defined for specific capability can be added in this optional section.
* For an example see the file 'env1-baw-double-pfs.properties'.


In the next versions I will also add configurations and scripts to perform the 'Production' type deployment for ADS and FNET capabilities.

At the moment, all the capabilities except ADP are present in the 'Starter' example configurations.

## Description of files '.yaml' ('kind: ICP4ACluster', in folder 'templates')

Template files must follow the rules imposed by the ICP4ACluster CR.

The content structure is dynamic based on the needs of each specific installation.

For the Foundation section (always mandatory) the 'shared_configuration' tag hosts the variables defined in the 'Main' section of the '.properties' type configuration file.

The section identified by the 'ldap_configuration' tag hosts the variables defined in the 'LDAP & IDP' section.

The further sections are variable according to your needs.

Refer to the 'cp4ba-cr-ref-baw.yaml' file for a complete and well-documented example.

Please ignore 'cp4ba-testinstaller-*' (used only to test the scripts)

For further information on the various tags and attributes specific to each capability you can consult the '...ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/descriptors/patterns' folder relating to the CP4BA Case Package manager.


## Prerequisites for installation

variabili env con key per creazione ibm-entitlement-key

repository a supporto


## ... esempi di installazione

For the deployment of Process Federation Server and Workflow Process Service, refer to my other git repositories of the cp4ba-* family

### ... scenario WfPS, PFS, BAW

### esempio di installazione case package in locale per consultazione CR di esempio.

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

## Installing
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=automation-installing

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


