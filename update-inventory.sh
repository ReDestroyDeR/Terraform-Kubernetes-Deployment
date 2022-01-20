#!/bin/bash
WORKER="worker"
MASTER="master"

rm -rf kubespray/inventory/cluster
cp kubespray/inventory/sample kubespray/inventory/cluster
declare -a IPS=$(IFS="\n" read -r -a ips <<< $(./get-ips.sh | sort) )
CONFIG_FILE=kubespray/inventory/cluster/hosts.yaml

# Master nodes are put in the beggining
KUBE_CONTROL_HOSTS=$(cat main.tfvars | grep "masters=" | sed "s/masters=//")


for i in ${!ips[@]}
do
  if [$i == 1] then
      python3 kubespray/contrib/inventory_builder/inventory.py ${ips[i] | sed "s/ /,/"}
  else
  python3 kubespray/contrib/inventory_builder/inventory.py e
done
