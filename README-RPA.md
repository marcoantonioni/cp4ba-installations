# RPA Day 2 tool

tool: cp4ba-rpa-day2-automations.sh


```bash
#=====================================
# Samples section
#=====================================

export CP4BA_INST_NAMESPACE="your-namespace"
export CP4BA_LOGGING_ENABLED="true"

#-------------------------------------------
# Tenants samples

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addtenants -f ../rpa-day2/tenants

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listtenants

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k removetenants -f ../rpa-day2/tenants

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k removetenants -t test1

#-------------------------------------------
# Users samples

# Use -t to telect a specific tenant, otherwise the tool automatically select the first tenant in list of managed by the user

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-1

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2 -t TENANT-A

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3 -t TENANT-B

./cp4ba-rpa-day2-automations.sh -u rpatenantadmin1 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2

./cp4ba-rpa-day2-automations.sh -u rpatenantadmin1 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-2 -t tenant-dev

./cp4ba-rpa-day2-automations.sh -u rpatenantadmin2 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3

./cp4ba-rpa-day2-automations.sh -u rpatenantadmin2 -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k addusers -r ../rpa-day2/user-roles-tenant-3 -t tenant-prod

#-------------------------------------------
# Credential samples

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listcredentials

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listcredentials -t TENANT-A

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k createcredential -t TENANT-A -g ../rpa-day2/credentials-1

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k deletecredential -t TENANT-A -g ../rpa-day2/credentials-1

#-------------------------------------------
# Credential Pools samples

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listcredentialpools -t TENANT-A

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k createcredentialpool -t TENANT-A -h ../rpa-day2/credential-pools-1

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k deletecredentialpool -t TENANT-A -h ../rpa-day2/credential-pools-1

#-------------------------------------------
# Computer Group samples

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listcomputergroups

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k createcomputergroup -i ../rpa-day2/computer-groups

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k deletecomputergroup -i ../rpa-day2/computer-groups

#-------------------------------------------
# Projects samples

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k listprojects -m ../rpa-day2/projects

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k createprojects -m ../rpa-day2/projects

./cp4ba-rpa-day2-automations.sh -u rpaadmin -p dem0s -c ../configs26/env1-runtime-rpa-managed.properties -k deleteprojects -m ../rpa-day2/projects
```
