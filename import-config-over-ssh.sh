#!/bin/bash
IFS=',' read -r -a master_ips <<< $(terraform output -json master_ips \
      | jq -r \
      | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
      | sed 's/"//g' \
      | sed -Ez 's/\n/,/g')

ip=${master_ips[0]}

echo "Changing chown to cmemb:cmember on master node for /etc/kubernetes/admin.conf"
ssh cmemb@$ip "sudo chown cmemb:cmember /etc/kubernetes/admin.conf"
echo "Downloading admin.conf as ~/.kube/config"
scp cmemb@$ip:/etc/kubernetes/admin.conf ~/.kube/config
echo "Change server ip in ~/.kube/config to "$ip
sed 's/127.0.0.1/'${ip}'/' ~/.kube/config --in-place
kubectl get nodes
