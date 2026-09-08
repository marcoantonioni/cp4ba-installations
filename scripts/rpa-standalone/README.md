# RPA Standalone

warning: Under construction

## Usage

### optional: override .properties values
```bash
export CP4BA_INST_RPA_MANAGED=[true | false]
export CP4BA_INST_RPA_NAMESPACE="my-rpa-test"
```

Install

```bash
# RPA managed configuration
_CFG="./env1-rpa1.properties" 
./cp4ba-install-rpa-standalone.sh -c $_CFG
```

```bash
# RPA unmanaged configuration
_CFG="./env1-rpa-standalone1.properties" 
./cp4ba-install-rpa-standalone.sh -c $_CFG
```
