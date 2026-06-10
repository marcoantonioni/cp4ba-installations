
_me=$(basename "$0")

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

checkPrereqTools () {
  which kubectl &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, kubectl not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi

  which jq &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, jq not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi

  which yq &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, yq not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi

  which oc &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_YELLOW}[✗] Error, oc not installed, cannot proceed.${_CLR_NC}"
  fi
}

showClusterConfiguration () {
  _CM_CLUS_CFG=$(oc get configmap cluster-config-v1 -n kube-system -o jsonpath='{.data.install-config}' | yq -o json)

  if [[ ! -z "${_CM_CLUS_CFG}" ]]; then
    _BASE_DOMAIN=$(echo $_CM_CLUS_CFG | jq .baseDomain | sed 's/"//g')
    _CLUS_NAME=$(echo $_CM_CLUS_CFG | jq .metadata.name | sed 's/"//g')
    _PUBLISH=$(echo $_CM_CLUS_CFG | jq .publish | sed 's/"//g')

    echo -e "${_CLR_GREEN}Cluster infos: Name[${_CLR_YELLOW}$_CLUS_NAME${_CLR_GREEN}] Base domain[${_CLR_YELLOW}$_BASE_DOMAIN${_CLR_GREEN}] Publish[${_CLR_YELLOW}$_PUBLISH${_CLR_GREEN}]"

    # control plane
    _WN_ARCH=$(echo $_CM_CLUS_CFG | jq .controlPlane.architecture | sed 's/"//g')
    _WN_HYPERT=$(echo $_CM_CLUS_CFG | jq .controlPlane.hyperthreading | sed 's/"//g')
    _WN_NAME=$(echo $_CM_CLUS_CFG | jq .controlPlane.name | sed 's/"//g')
    _WN_REPL=$(echo $_CM_CLUS_CFG | jq .controlPlane.replicas | sed 's/"//g')
    echo -e "${_CLR_GREEN}Control plane group: Name[${_CLR_YELLOW}$_WN_NAME${_CLR_GREEN}] Architecture[${_CLR_YELLOW}$_WN_ARCH${_CLR_GREEN}] Hyperthreading[${_CLR_YELLOW}$_WN_HYPERT${_CLR_GREEN}] Replicas[${_CLR_YELLOW}$_WN_REPL${_CLR_GREEN}]"

    # worker node groups
    _counter=0
    echo $_CM_CLUS_CFG | jq -c '.compute[]' | while read c; do
      _WN_ARCH=$(echo "$c" | jq .architecture | sed 's/"//g')
      _WN_HYPERT=$(echo "$c" | jq .hyperthreading | sed 's/"//g')
      _WN_NAME=$(echo "$c" | jq .name | sed 's/"//g')
      _WN_REPL=$(echo "$c" | jq .replicas | sed 's/"//g')
      _counter=$((_counter + 1))
      echo -e "${_CLR_GREEN}Compute group: [${_CLR_YELLOW}$_counter${_CLR_GREEN}]: Name[${_CLR_YELLOW}$_WN_NAME${_CLR_GREEN}] Architecture[${_CLR_YELLOW}$_WN_ARCH${_CLR_GREEN}] Hyperthreading[${_CLR_YELLOW}$_WN_HYPERT${_CLR_GREEN}] Replicas[${_CLR_YELLOW}$_WN_REPL${_CLR_GREEN}]"
    done

    # network type
    _CN_NETTYPE=$(echo $_CM_CLUS_CFG | jq -c .networking.networkType | sed 's/"//g')
    echo -e "${_CLR_GREEN}Network type [${_CLR_YELLOW}$_CN_NETTYPE${_CLR_GREEN}]" 

    # cluster networks
    _counter=0
    echo -e -n "${_CLR_GREEN}  Cluster networks: " 
    echo $_CM_CLUS_CFG | jq -c '.networking.clusterNetwork[]' | while read c; do
      _CN_CIDR=$(echo "$c" | jq .cidr | sed 's/"//g')
      _counter=$((_counter + 1))
      echo -e -n "${_CLR_GREEN}CIDR[${_CLR_YELLOW}$_CN_CIDR${_CLR_GREEN}] "
    done
    echo -e ""

    # machine networks
    _counter=0
    echo -e -n "${_CLR_GREEN}  Machine networks: " 
    echo $_CM_CLUS_CFG | jq -c '.networking.machineNetwork[]' | while read c; do
      _CN_CIDR=$(echo "$c" | jq .cidr | sed 's/"//g')
      _counter=$((_counter + 1))
      echo -e -n "${_CLR_GREEN}CIDR[${_CLR_YELLOW}$_CN_CIDR${_CLR_GREEN}] "
    done
    echo -e ""

    # service networks
    _counter=0
    echo -e -n "${_CLR_GREEN}  Service networks: " 
    echo $_CM_CLUS_CFG | jq -c '.networking.serviceNetwork[]' | while read c; do
      _CN_SN=$(echo "$c" | jq . | sed 's/"//g')
      _counter=$((_counter + 1))
      echo -e -n "${_CLR_GREEN}[${_CLR_YELLOW}$_CN_SN${_CLR_GREEN}] "
    done
    echo -e ""

    # platform
    echo -e "${_CLR_GREEN}Platform"

    _BM=$(echo $_CM_CLUS_CFG | jq '.platform?.baremetal // ""')
    if [[ ! -z "$_BM" ]]; then
      _LIBVIRT=$(echo $_BM | jq .libvirtURI | sed 's/"//g')
      echo -e "${_CLR_GREEN}  LibvirtURI [${_CLR_YELLOW}$_LIBVIRT${_CLR_GREEN}]"

      # api vips
      _counter=0
      echo -e -n "${_CLR_GREEN}  API VIPs " 
      echo $_BM | jq -c '.apiVIPs[]' | while read c; do
        _ITEM=$(echo "$c" | jq . | sed 's/"//g')
        _counter=$((_counter + 1))
        echo -e -n "${_CLR_GREEN}[${_CLR_YELLOW}$_ITEM${_CLR_GREEN}] "
      done
      echo -e ""

      # ingres vips
      _counter=0
      echo -e -n "${_CLR_GREEN}  Ingress VIPs " 
      echo $_BM | jq -c '.ingressVIPs[]' | while read c; do
        _ITEM=$(echo "$c" | jq . | sed 's/"//g')
        _counter=$((_counter + 1))
        echo -e -n "${_CLR_GREEN}[${_CLR_YELLOW}$_ITEM${_CLR_GREEN}] "
      done
      echo -e ""

      # hosts
      _counter=0
      echo -e "${_CLR_GREEN}  Hosts" 
      echo $_BM | jq -c '.hosts[]' | while read c; do
        _HNAME=$(echo "$c" | jq .name | sed 's/"//g')
        _HROLE=$(echo "$c" | jq .role | sed 's/"//g')
        _counter=$((_counter + 1))
        echo -e "${_CLR_GREEN}    Name[${_CLR_YELLOW}$_HNAME${_CLR_GREEN}] Role[${_CLR_YELLOW}$_HROLE${_CLR_GREEN}]"
      done

    fi
  fi
}

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Cluster configuration details${_CLR_NC}"
showClusterConfiguration