#!/bin/bash
function get_out {
  IFS=','
  read -r -a global_arr <<< $(terraform output -json $1\
        | jq -r \
        | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
        | sed 's/"//g' \
        | sed -Ez 's/\n/,/g')
}

for target in master_ips worker_ips
do
  get_out $target
  for index in ${!global_arr[@]}
  do
    virsh shutdown $( echo $target | sed "s/_.*/-node-$index/" | sed 's/master-node/kube-master/' | sed 's/worker-node/kube-worker/' )
  done
done
