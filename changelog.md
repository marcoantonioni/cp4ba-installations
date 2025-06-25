
# Change Log

## External dependencies (please update your supporting repo copies)

2024-02-20: updated project cp4ba-utilities, new 'cp4ba-tls-entry-point', utility to apply your TLS certificate on ZenService

2024-01-29: updated project cp4ba-idp-ldap, onboard-users.sh modified admin roles for cp4admin user

2024-01-29: updated project cp4ba-idp-ldap, modified 'sed -i' command for compatibility with Darwing platform limitation


## [1.1.8] - 2025-06-23

### Added

### Changed
Support for v25.x

### Fixed
installCasePackMgr pattern matching to support v25


## [1.1.7] - 2025-04-03

### Added

### Changed

### Fixed
waitForBawStatefulSetReady



## [1.1.6] - 2025-03-06

### Added

### Changed
Changed predefined value in template files, now is

  <b>sc_deployment_profile_size: "${CP4BA_INST_DEPL_PROFILE_SIZE}"</b>


### Fixed

## [1.1.5] - 2025-03-02

### Added

GenAI configuration for "starter" deployment.

GenAI "production" configuration will arrive as soon as possible.

see section 'BAStudio GenAI configuration' in .properties file
```
# BAStudio GenAI configuration
export CP4BA_INST_GENAI_ENABLED="true"
export CP4BA_INST_GENAI_WX_AUTH_SECRET="watsonx-ai-secret"
# set your values here or set following env vars in shell before run main script 
# export _WX_USERID=, export _WX_APIKEY=, export _WX_PRJ_ID=, export _WX_URL_PROVIDER=
export CP4BA_INST_GENAI_WX_USERID="my-user-id@ibm.com"
export CP4BA_INST_GENAI_WX_APIKEY="your-apy-key-from-watsonx-ibm-cloud"
export CP4BA_INST_GENAI_WX_PRJ_ID="your-project-id-from-watsonx-ibm-cloud"
export CP4BA_INST_GENAI_WX_URL_PROVIDER="https://your-region.ml.cloud.ibm.com"
```
for details see 'scripts/cp4ba-configure-genai.sh'

### Changed

### Fixed

## [1.1.4] - 2025-02-05

### Added

### Changed

Added clarification messages for missing parameters and invalid combinations 

### Fixed


## [1.1.3] - 2024-08-12

### Added

### Changed

Moved .sql template files in dedicated folder 'templates-sql'.

### Fixed


## [1.1.2] - 2024-08-11

### Added

### Changed

Delete PFS operator to avoid federation failure (probably failed credential update), is a workaround.
Currently only supports configuration with operators and deployment in the same namespace.
Will be changed soon with dual namespace support.

### Fixed


## [1.1.1] - 2024-08-10

### Added

### Changed

Improved PFS federation fow BAW servers.

The algorithm waits for statefulset creation and readiness.

### Fixed


## [1.1.0] - 2024-08-05

### Added

Support for v24.x deployment (Starter configuration)

Now version and templetes are splitted in 'configs23' / 'templates23' and 'configs24' / 'templates24' folders.

### Changed

Some environment variables added for v24 version.

### Fixed


## [1.0.16] - 2024-07-02

### Added

Support for v24.x Case package manager

Contents split for 

https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-automation

and

https://github.com/icp4a/cert-kubernetes/tree

### Changed

### Fixed

## [1.0.15] - 2024-07-01

### Added

Variable CP4BA_AUTO_SEPARATE_OPERATOR and CP4BA_AUTO_CS_SERVICE_NAMESPACE in all properties files

### Changed

### Fixed

## [1.0.14] - 2024-06-25

### Added

Variable CP4BA_AUTO_AIRGAP_MODE in all properties files

### Changed

### Fixed


## [1.0.13] - 2024-04-02

### Added

### Changed

### Fixed

* cp4ba-one-shot-installation.sh
  checkPrepreqTools: added test for 'yq' prerequisite

## [1.0.12] - 2024-02-20

### Added

Add custom TLS certificate on ZenService

### Changed

* cp4ba-deploy-env.sh

### Fixed
n/a


## [1.0.11] - 2024-02-08
New deployment option, configuration/template for FNCM Workflow.

New deployment option, configuration/template for ADS Runtime.

Tested with CP4BA v23.0.2-IF001

### Added
Added 'ADS' runtime deployment configurations (.properties, .yaml)


### Changed
Content deployment configurations (.properties, .yaml, .sql)
Up to 5 ObjectStores

* cp4ba-create-databases.sh
* cp4ba-create-secrets.sh

### Fixed
n/a


## [1.0.10] - 2024-01-30
New deployment option, configuration/template for Content (FNCM) CR.

### Added
Added 'Content' deployment configurations (.properties, .yaml, .sql)

### Changed
* cp4ba-one-shot-installation.sh
* cp4ba-deploy-env.sh
* cp4ba-create-secrets.sh
* cp4ba-create-databases.sh

### Fixed
n/a


## [1.0.9] - 2024-01-27
Minimal adjustments

### Added
n/a

### Changed
Logged activities
Renamed some configuration samples

### Fixed
n/a


## [1.0.8] - 2024-01-25
Minimal adjustments

### Added
n/a

### Changed
cp4ba-one-shot-installation.sh
* launch of ./cp4ba-deploy-env.sh with variable num of params 

### Fixed
cp4ba-install-db.sh: wrong namespace in waitForClustersPostgresCRD


## [1.0.7] - 2024-01-25
Minimal adjustments

### Added
n/a

### Changed
cp4ba-deploy-env.sh
* waitDeploymentReadiness: code enforcement for data analysis in config map 'access-info'

### Fixed
n/a


## [1.0.6] - 2024-01-24
Minimal adjustments

### Added
n/a

### Changed
cp4ba-deploy-env.sh
* waitDeploymentReadiness: text of wait messages
* cp4ba-create-databases.sh: changed timeout limit wait pod ready (now 30 minutes to manage parallel installations load)
* cp4ba-deploy-env.sh: deployPreEnv / deployPostEnv, moved DB inst as Post action because of PostgreSQL CRD not yet available
* cp4ba-install-db.sh: waitForClustersPostgresCRD, added loop for CRD conditions 

### Fixed
* Timeout in 'waitForClustersPostgresCRD' during PostgreSQL installation when clusters.postgresql.k8s.enterprisedb.io not yet deployed


## [1.0.5] - 2024-01-22
Minimal adjustments

### Added
n/a

### Changed
cp4ba-deploy-env.sh
* waitDeploymentReadiness: update federate-only logic

### Fixed
n/a
 
## [1.0.4] - 2024-01-22
Minimal adjustments

### Added
n/a

### Changed
cp4ba-deploy-env.sh
* waitDeploymentReadiness: update wait-only logic

### Fixed
n/a
 
## [1.0.3] - 2024-01-22
Minimal adjustments

### Added
n/a

### Changed
cp4ba-deploy-env.sh
* federateBawsInDeployment: added PFS readiness check

### Fixed
n/a
 
## [1.0.2] - 2024-01-22
Minimal adjustments

### Added
cp4ba-install-db.sh
* waitForClustersPostgresCRD: wait for Postgres CRD creation

### Changed
cp4ba-deploy-env.sh
* deployPFS: launch pfs-deployment in embedded mode  
* waitDeploymentReadiness: added PFS readiness check

### Fixed
n/a
 
## [1.0.1] - 2024-01-19
Minor fixes

### Added
Added PFS configutation variable
 
### Changed
Separated logic for Federation and Hosting federated ProcessPortal to have only selected BAWs as federated ProcessPortal hosts

### Fixed
Federation function
 
## [1.0.0] - 2024-01-19
First release

### Added
n/a

### Changed
n/a
   
### Fixed
n/a
 
