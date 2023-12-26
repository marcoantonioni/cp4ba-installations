#!/bin/bash

_me=$(basename "$0")

_CFG=""
_WAIT=false
_SILENT=false
_ERROR=0

_maxWait=60

#--------------------------------------------------------
# read command line params
while getopts c:t:ws flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        t) _maxWait=${OPTARG};;
        w) _WAIT=true;;
        s) _SILENT=true;;
    esac
done


_WAIT=true
createSecrets () {

echo $_maxWait

  if [[ "${_WAIT}" = "true" ]]; then
    _seconds=0
    until [[ $_seconds -gt $_maxWait ]];
    do
      sleep 1
      ((_seconds=_seconds+1))
    done
    echo ""
  fi

}

createSecrets