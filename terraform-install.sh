#!/bin/bash
# Parse main.tfvars
function inject_awk {
  local tmp=$(awk -v target=$1 'BEGIN { FS = "=" }; { if ($1 == target) { print $2 } }' ./main.tfvars)
  printf $tmp | if [[ $(wc -L) -eq 0 ]]; then printf $2; else printf $tmp; fi
}

hostname=$(inject_awk "hostname" "kubenode")        # { default = "kubenode" }
domain=$(inject_awk "domain" "kubenode.com")        # { default = "kubenode.com" }
m_memoryMB=$(inject_awk "m_memoryMB" "1024")        # { default = 1024*1 }
m_cpu=$(inject_awk "m_cpu" "1")                     # { default = 1 }
w_memoryMB=$(inject_awk "w_memoryMB" "1024")        # { default = 1024*1 }
w_cpu=$(inject_awk "w_cpu" "1")                     # { default = 1 }
masters=$(inject_awk "masters" "0")                 # { default = 0 }
workers=$(inject_awk "workers" "1")                 # { default = 1 }
base_gb=$(inject_awk "base_gb" "10")                # { default = 10 }
data_gb=$(inject_awk "data_gb" "10")                # { default = 10 }

LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_CYAN='\033[1;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m'

printf "${LIGHT_CYAN}MASTER NODE SPEC:\n"
printf "${LIGHT_GREEN}- ${WHITE}hostname : ${YELLOW}$hostname\n"
printf "${LIGHT_GREEN}- ${WHITE}domain   : ${YELLOW}$domain\n"
printf "${LIGHT_GREEN}- ${WHITE}CPU Cores: ${YELLOW}$m_cpu\n"
printf "${LIGHT_GREEN}- ${WHITE}RAM MB   : ${YELLOW}$m_memoryMB\n"
printf "${LIGHT_GREEN}- ${WHITE}INSTANCES: ${YELLOW}$masters\n"
printf "\n"
printf "${LIGHT_CYAN}WORKER NODE SPEC:\n"
printf "${LIGHT_GREEN}- ${WHITE}hostname : ${YELLOW}$hostname\n"
printf "${LIGHT_GREEN}- ${WHITE}domain   : ${YELLOW}$domain\n"
printf "${LIGHT_GREEN}- ${WHITE}CPU Cores: ${YELLOW}$w_cpu\n"
printf "${LIGHT_GREEN}- ${WHITE}RAM MB   : ${YELLOW}$w_memoryMB\n"
printf "${LIGHT_GREEN}- ${WHITE}INSTANCES: ${YELLOW}$workers\n"
printf "\n"
printf "${LIGHT_GREEN}OS image - ${YELLOW}Ubuntu Focal 20.04 Cloud Server\n"
printf "\n"
printf "${LIGHT_CYAN}Total: \n"
printf "${LIGHT_GREEN}CPU: ${YELLOW}$(( $masters * $m_cpu + $workers * $w_cpu )) VCORES\n"
printf "${LIGHT_GREEN}RAM: ${YELLOW}$(( $masters * $m_memoryMB + $workers * $w_memoryMB )) MB\n"
printf "${LIGHT_GREEN}SPACE: ${YELLOW}$(( ($masters * $base_gb + $workers * $data_gb) )) GB\n"
printf "${LIGHT_GREEN}VIRTUAL MACHINES: ${YELLOW}$(( $masters + $workers ))\n"
printf "\n${LIGHT_RED}Are you sure want to install? ${WHITE}[Only ${LIGHT_GREEN}'Y/y' ${WHITE}will be accepted as confirmation] "
read -p "" -n 1 -r
printf "\n"

if [[ $REPLY =~ ^[Yy]$ ]]
then
  terraform apply -var-file=main.tfvars
  printf "${LIGHT_GREEN}=== Waiting for start of SSH Servers and start of Docker Daemon ===\n"
  sleep 15
  printf "${LIGHT_GREEN}Trying installing Rancher Agent on target Virutal Machines\n"
  ./register-rancher.sh
else
  printf "Aborting VM install"
fi
