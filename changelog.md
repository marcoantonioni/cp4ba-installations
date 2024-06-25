
# Change Log

## External dependencies (please update your supporting repo copies)

2024-02-20: updated project cp4ba-utilities, new 'cp4ba-tls-entry-point', utility to apply your TLS certificate on ZenService

2024-01-29: updated project cp4ba-idp-ldap, onboard-users.sh modified admin roles for cp4admin user

2024-01-29: updated project cp4ba-idp-ldap, modified 'sed -i' command for compatibility with Darwing platform limitation

## [1.0.14] - 2024-06-25

### Added

Variable CP4BA_AUTO_AIGRAP_MODE in all properties files

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
 
