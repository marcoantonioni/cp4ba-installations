#!/bin/bash

_X=false
_PREVAL=false

# read command line params
while getopts x:prevalidate: flag
do
    case "${flag}" in
        x) _X=${OPTARG};;
        prevalidate) _PREVAL=${OPTARG};;
    esac
done

echo "_X: "$_X
echo "_PREVAL: "$_PREVAL

