# cp4ba-installations

Utilities for IBM Cloud Pak® for Business Automation

<i>Last update: 2024-02-01</i> use '<b>1.0.10-stable</b>' (see changelog.md for details)

## Description of the contents of this repository

In this repository a series of procedures are available for the fully automated 'silent' installation of IBM Cloud Pak for Business Automation environments in Openshift clusters.

The contents must be understood as examples of training on the topic of CP4BA IT Operations. 

Obviously it is without any kind of support. Use them freely, modify them where necessary according to your needs.

This repository can be useful for professionals who create disposable environments dedicated to demonstrations/tests of the CP4BA product (IBMers, IBM Partners and Customers with active license to access to IBM Container Registry).

Please read the DISCLAIMER section carefully.

This repository was created to simplify my IBM CP4BA study and PoX activities.

Even if the installations as per the IBM user manual are relatively simple, they must always be contextualized in the various deployment combinations.

Some activities, such as the installation of the operators (the first step) are extremely simple, while the second activity can be complex and difficult to implement if you do not have a good knowledge of the capability you intend to deploy.

The scripts available in the CP4BA Case Manager package are extremely powerful and should be your primary choice for professional installations and configurations where for example the various databases and LDAP servers are external to the Openshift cluster, and the configurations are made in advance of the deployment phase of CR ICP4ACluster.

The main objective of this repository is the further simplification and automation of the activities required by the official manuals.

I hope it can help you and make CP4BA adoption even easier for novices.

## How this idea was born

One day I was bored with having to repeat the same sequence of activities often and I asked myself: "what if I automate everything?"

Thinking: Maybe I could use a simple properties file, a predefined template for various scenarios, and a single command that creates the configuration by merging the template and properties and then creating a containerized LDAP server, one or more containerized PostgreSQL instances and finally the deployment of CR ICP4ACluster...and also execute the onboarding of LDAP users into Pak IDP.
Maybe to exaggerate even more I could also add a Portal Federation Server and configure the federation of the various BAW and WfPS instances defined in the template.

In the end I created this repository and since my role in IBM is that of presales I decided to make it public to help customers, business partners and also my IBM colleagues.

I cannot exclude that in some time I will try to define some 'Skills' in <b>IBM watsonx Orchestrate</b> to simplify these activities even more ;)

## Compatibility with CP4BA versions

These tools were developed starting from CP4BA v23.0.2 and Case Installation Manager v5.1.0.

The CRs in yaml format that you will find in the configuration examples may not be backwards compatible.

## Mandatory and optional tools for running scripts

A linux box (scripts are only available in the bash shell)

'oc' Openshift CLI client (mandatory)

'jq' tool (mandatory)

'yq' tool (mandatory, also available in IBM's CP4BA Case Package Manager)

'envsubst' (mandatory)

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

The 'templates' folder contains a series of yaml files that respect the configuration structure of the CR ICP4ACluster with the values area containing the '${..key..}' placeholders which will be replaced by the values of the properties file used for deployment .

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

At the moment, all the capabilities except ADP are defined in the 'Starter' example configurations.

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

You must export in your bash shell the entitlement key with its value

```
export CP4BA_AUTO_ENTITLEMENT_KEY="...your-key..." # begins with 'ey'
```
For entitlement key see link 'Entitlement keys' in References section.

For a complete overview see link 'Environment variables for silent mode installation' in References section.

For ROKS based installations export 'CP4BA_AUTO_CLUSTER_USER' var with your account id value.
```
export CP4BA_AUTO_CLUSTER_USER="IAM#...your-id..."
```

## List of supporting 'cp4ba-*' repositories

For the autonomous completion of all installation tasks you need other supporting repositories.
To ease your first run use pre-existing configurations. 
Clone the following repositories within a parent folder.

```
# --> cd <your-parent-folder>

# mandatory
git clone https://github.com/marcoantonioni/cp4ba-installations.git
git clone https://github.com/marcoantonioni/cp4ba-casemanager-setup.git
git clone https://github.com/marcoantonioni/cp4ba-idp-ldap.git

# mandatory only if PFS in configuration
git clone https://github.com/marcoantonioni/cp4ba-process-federation-server.git

# for Workflow Process Service installation (not automated using 'cp4ba-installations')
git clone https://github.com/marcoantonioni/cp4ba-wfps.git

# Useful for application deployment and other utilities
git clone https://github.com/marcoantonioni/cp4ba-utilities.git
```

This is an example of cloned folders

```
├── cp4ba-casemanager-setup
├── cp4ba-idp-ldap
├── cp4ba-installations
├── cp4ba-process-federation-server
├── cp4ba-utilities
└── cp4ba-wfps
```

## Installation examples

Before begin an installation

1. Login to your cluster
```
oc login https://<cluster-ip>:<port> -u <cluster-admin> -p <password>
```
or with token
```
oc login --token=sha256~...your-token-data.... --server=https://api...your-hostname....com:6443
```

2. Export entitlement key and optionally if ROKS the cluster user id 
```
export CP4BA_AUTO_ENTITLEMENT_KEY="...your-key..." # begins with 'ey'
export CP4BA_AUTO_CLUSTER_USER="IAM#...your-id..."
```

now from parent of cloned folders move into installation folder 'scripts'
```
cd ./cp4ba-installations/scripts
```

<b><u>Note: The Openshift user you use to perform the installations must have the necessary grants as per IBM documentation</u></b>

[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=sucioc-installing-cloud-pak-catalogs-operators](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=sucioc-installing-cloud-pak-catalogs-operators)

If you do not have a full-grants user, ask your administrator to provide you with the necessary information to install operator catalogs and create new namespaces.

If this is not possible and you necessarily have to delegate the administrator to create the catalogs and a namespace for which you will still have the namespace administration grants, you can follow the instructions for deploying an environment in an already created namespace and operators already installed (see '5. Deployment in already created namespace').

Note: You can run installations of different configurations in parallel in different shells, each temporary file is created with random naming and does not create interference.

### 1. Production deployment - LDAP/DB/BAW

For the first installation example we will use a ready and configured properties file, this configuration deploys the 'Production' type with:

- Foundation components
- 1 LDAP local to this installation namespace + users IAM onboarding
- 1 DB Server
- 1 BAW full (Case+BPM)

Once the installation is complete you will find the deployment within the 'cp4ba-test1-baw' namespace.
If you want to change the namespace name, change the value of the 'CP4BA_INST_NAMESPACE' variable.

We'll use the simplest method, we'll run a single shell script named 'cp4ba-one-shot-installation.sh' with following parameters:

- '-c' parameter to indicate the configuration file (.properties) that will guide the installation
- '-m' parameter that requires an online download of the IBM CP4BA Case Package Manager (download in a temporary directory then removed)
- '-v' parameter indicating the version of the IBM CP4BA Case Package Manager to use

Note: Version 5.1.0 corresponds to CP4BA version v23.0.2

Ready to begin ? <i>GO !!!</i>
```
# set your configuration file
CONFIG_FILE=../configs/env1-baw.properties

# run the real 'one-shot' CP4BA installation command
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0
```

Well, now you have to... no... you don't have to do anything more, just wait for the procedure to finish.

The estimated time for an environment with worker nodes with 16 CPUs and 64 GB is approximately 70/80 minutes.

As you will notice by taking a look at the creation of the various pods, first of all the set of functions of the Foundation layer is installed and only subsequently will the various Operators start the creation of the capabilities defined in the ICP4ACluster CR.

You will notice that some pods remain in 'Pending' state or perform restarts. No alarms because in this scenario the installation and configuration of the databases and object stores to support the BAW are performed by specific Jobs which may not find all the necessary prerequisites and then attempt subsequent processing until successful completion. This is the philosophy of Kubernetes.

At the end of installation you will find into <b>output</b> folder three files (.yaml, .sql, .txt) as described before.

```
./cp4ba-installations/
├── configs
├── output <<--- .yaml, .sql, .txt
├── scripts
└── templates
```

Once the installation is complete, in the .txt file you will find all the URLs of the consoles of the various products installed.

To log in you can use the users/credentials that are defined in the .ldif file in the 'configs' folder.

The administration user, if you have not made any changes, is 'cp4admin' and the password (for all users) is 'dem0s', it's a ZERO.

Pay attention: even if the operators are all in the 'Ready' state, some configurations trigger a restart of various pods and these could cause errors (usually 500) when accessing the web consoles or on REST calls.
Usually after a short time (2/3 minutes, also depends on the 'limits.cpu' set) all the features are ready for use.

To access the CP4BA console you can use the URL composed of the following sections:

```
https://cpd-<your-namespace>.apps.<your-target-domain>/
```

this is a complete example
```
https://cpd-cp4ba-baw-double-pfs.apps.656d73e8eb178100111c14ac.cloud.techzone.ibm.com
```

### 2. Production deployment - LDAP/DB/2-BAWs/PFS

For the second installation example we will use a ready and configured properties file, this configuration deploys the 'Production' type with:

- Foundation components
- 1 LDAP local to this installation namespace + users IAM onboarding
- 1 DB Server
- 1 BAW full (Case+BPM)
- 1 BAW Workflow only (BPM)
- 1 PFS

Note: 'Baw full' is federated only, 'BAW Workflow' is federated and host federated ProcessPortal dashboard.

```
# set your configuration file
CONFIG_FILE=../configs/env1-baw-double-pfs.properties

# run the real 'one-shot' CP4BA installation command
./cp4ba-one-shot-installation.sh -c ${CONFIG_FILE} -m -v 5.1.0
```

The average time for an installation of this type varies between 90/100 minutes.

### 3. Starter deployment - Authoring environment all but ADP/ODM

In this third example we install an Authoring environment for all capabilities except ADP and ODM.
This is the list of components:

* ads_designer
* ads_runtime
* bai
* baml
* baw_authoring
* case
* cmis
* content_integration
* css
* ier
* pfs
* tm
* workstreams

Note: For 'Starter' type deployments the LDAP and databases are installed by the Operators. The user names/passwords can be obtained from secret 'cp4adeploy-openldap-customldif', the Pak consoles URL from config map '
icp4adeploy-cp4ba-access-info'.

If you also want to add ODM to the Authoring environment you must add 'decisions' in 'CP4BA_INST_DEPL_PATTERNS' and 'decisionCenter,decisionRunner,decisionServerRuntime' in 'CP4BA_INST_OPT_COMPONENTS'.

for example
```
export CP4BA_INST_DEPL_PATTERNS="<other-patterns>,decisions"
export CP4BA_INST_OPT_COMPONENTS="<other-components>,decisionCenter,decisionRunner,decisionServerRuntime"
```

### 4. Local Case Manager package installation for sample CR consultation

If you want to install IBM CP4BA Case Package Manager on your desktop even just to consult the possible configuration options (in patterns folder of package) you can use the command 'cp4ba-casemgr-install.sh' in repository 'cp4ba-casemanager-setup'.

Use following parameters:
```
-d target-directory
-v(optional) package-version
-n(optional) move-to-scripts-folder
-r(optional) remove-tar-file
-s(optional) show-available-versions
```

Show available versions
```
./cp4ba-casemgr-install.sh -s
```
Note: Jan 2024, for v5.1.0 is reported in 'appVersion' a value of '23.2.0', must be intended as '23.0.2'

Install latest package version into folder, remove .tar file then move shell to 'scripts' folder
```
_CMGR_FOLDER="/tmp/mycmgr"
mkdir -p ${_CMGR_FOLDER}
./cp4ba-casemgr-install.sh -d ${_CMGR_FOLDER} -n -r
```

Install package version '4.1.6+20230713.011847' for CP4BA version '22.0.2-IF006LA01'
```
_CMGR_FOLDER="/tmp/mycmgr-22.0.2"
mkdir -p ${_CMGR_FOLDER}
./cp4ba-casemgr-install.sh -d ${_CMGR_FOLDER} -n -r -v "4.1.6+20230713.011847"
```

### 5. Deployment in already created namespace

If you have a namespace in which you have already installed the CP4BA operators and have locally installed IBM CP4BA Case Manager package, you can manually execute the following commands
```
_CFG=../configs/env1-baw.properties
_LDAP_CFG_FILE=../configs/_cfg-production-ldap-domain.properties
_SCRIPTS=/tmp/mycmgr/ibm-cp-automation-5.1.0/...../crs/cert-kubernetes/scripts

./cp4ba-install-operators.sh -c ${_CFG} -s ${_SCRIPTS}
./cp4ba-deploy-env.sh -c ${_CFG} -l ${_LDAP_CFG_FILE}
```
This is not the best solution but it still works without users onboarding in IAM (must be done manually via web console or using script 'onboard-users.sh' in repo 'cp4ba-idp-ldap').

### 6. For IBMers, Business Partners and others who may have needs

If you need to present a hands-on workshop on CP4BA and want to make a dedicated environment available for each guest, you can configure multiple environments with the same configuration file in this way (adapt the variables based on your environment).

PAY ATTENTION: Adapt this script using a different shell tool if you are not using 'gnome-terminal' (default in an RH/CentOS linux box with graphic desktop).

#### 6.1 Install multiple CP4BA environments

<b>IMPORTANT</b> comment out the definition of var <b>CP4BA_INST_ENV</b> in <i>.properties</i> file.

```
# set the name of your configuration file
_CONFIG_FILE="../configs/multienv.properties"

# set the name-segment suffix for the envs (it will be workshop-env-1, workshop-env-2, and so on)
_MULTI_ENV="workshop-env"

# suffix for environment name
i=1
# tot num of envs (pay attention and evaluate 'max' based on your Openshift cluster size and type of deployment)
max=2
while [[ $i -le $max ]]
do
  # name of environment
  export CP4BA_INST_ENV="${_MULTI_ENV}-${i}"

  # !!! set your path to scripts
  export _S="/home/marco/cp4ba-projects/cp4ba-installations/scripts"
  export _C=${_CONFIG_FILE}
  gnome-terminal -q --geometry=140x24 -t "CP4BA-${i}" -- bash -c 'export _T=$(($RANDOM % 30)); sleep $_T; cd ${_S}; ./cp4ba-one-shot-installation.sh -c ${_C} -m -v 5.1.0; exec bash -i'
  ((i = i + 1))
done
```

#### 6.2 Clean multiple CP4BA environments
```
# set the namespace prefix for the envs (it will be cp4ba-workshop-env-1, cp4ba-workshop-env-2, and so on)
_MULTI_ENV="cp4ba-workshop-env"

# suffix for environment name
i=1
# tot num of envs
max=2
while [[ $i -le $max ]]
do
  export _N="${_MULTI_ENV}-${i}"

  # !!! set your path to scripts
  export _S=/home/marco/cp4ba-projects/cp4ba-utilities/remove-cp4ba
  gnome-terminal -q --geometry=140x24 -t "CP4BA-${i}" -- bash -c "cd ${_S}; ./cp4ba-remove-namespace.sh -n ${_N}"
  ((i = i + 1))
done
```

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


# References

## Installing
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=automation-installing

## Quick reference Q&A for online deployments
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=deployment-quick-reference-qa-online-deployments

## Entitlement keys - MyIBM Container Software Library
https://myibm.ibm.com/products-services/containerlibrary

## Environment variables for silent mode installation
https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=reference-environment-variables-silent-mode-installation

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

### envsubst
[https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html)

### Openssl
[https://www.openssl.org/](https://www.openssl.org/)

### Home of CP4BA Case Installation tool
https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-automation

## CP4BA Silent installation
[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=o2isdbrs-option-2b-setting-up-cluster-in-silent-mode](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=o2isdbrs-option-2b-setting-up-cluster-in-silent-mode)

[https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=reference-environment-variables-silent-mode-installation](https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/23.0.2?topic=reference-environment-variables-silent-mode-installation)


