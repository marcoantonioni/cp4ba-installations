
# Change Log

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
 
