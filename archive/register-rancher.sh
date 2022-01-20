#!/bin/bash
IFS=',' read -r -a master_ips <<< $(terraform output -json master_ips \
      | jq -r \
      | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
      | sed 's/"//g' \
      | sed -Ez 's/\n/,/g')

IFS=',' read -r -a worker_ips <<< $(terraform output -json worker_ips \
      | jq -r \
      | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
      | sed 's/"//g' \
      | sed -Ez 's/\n/,/g')

IFS=',' read -r -a rancher_ips <<< $(terraform output -json rancher_ips \
      | jq -r \
      | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
      | sed 's/"//g' \
      | sed -Ez 's/\n/,/g')


LIGHT_GREEN='\033[1;32m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'
RANCHER_HOST=rancher_ips[0]

printf "${YELLOW}CONFIGURING MASTER NODES\n"

for ip in ${!master_ips[*]}
do
    if [[ $(($ip % 2)) == 0 ]]
    then
      printf "${LIGHT_CYAN}"
    else
      printf "${LIGHT_GREEN}"
    fi
    ssh cmemb@${master_ips[$ip]} "sudo docker run -e CATTLE_AGENT_IP="${master_ips[$ip]}"  -e CATTLE_HOST_LABELS='role=master'  --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.11 ${RANCHER_HOST}/v1/scripts/D434748154B6836075BB:1609372800000:BPUgipUHnEJBYi379K0FDW6WC5Q"
done

printf "${YELLOW}CONFIGURING WORKER NODES\n"

for ip in ${!worker_ips[*]}
do
    if [[ $(($ip % 2)) == 0 ]]
    then
      printf "${LIGHT_CYAN}"
    else
      printf "${LIGHT_GREEN}"
    fi
    ssh cmemb@${worker_ips[$ip]} "sudo docker run -e CATTLE_AGENT_IP="${worker_ips[$ip]}"  -e CATTLE_HOST_LABELS='role=worker'  --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.11 ${RANCHER_HOST}/v1/scripts/D434748154B6836075BB:1609372800000:BPUgipUHnEJBYi379K0FDW6WC5Q"
done

printf "\n${WHITE}Finished! Check your Rancher Instance! ${LIGHT_CYAN}$(docker ps | grep rancher/server)${NC}\n"
