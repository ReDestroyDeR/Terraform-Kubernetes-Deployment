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
    # Temporary fix.
    sudo sed -i 's/::1 ip6-localhost ip6-loopback/::1 localhost ip6-localhost ip6-loopback/' /etc/hosts
  done
done
