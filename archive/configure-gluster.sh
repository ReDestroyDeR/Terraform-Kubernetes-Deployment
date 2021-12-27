#!/bin/bash
echo "Configuring Gluster Cluster"
IFS=',' read -r -a gluster_ips <<< $(terraform output -json gluster_ips \
      | jq -r \
      | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/{gsub(/^ +| +$/, "", $0); print}' \
      | sed 's/"//g' \
      | sed -Ez 's/\n/,/g')

gluster_nodes_export=$(for i in ${!gluster_ips[*]}; do printf "node%s:/data/vdb1/brick " "${i}"; done)

for ip in ${gluster_ips[*]}
do
  for ip_index in ${!gluster_ips[*]}
  do
    lip=${gluster_ips[${ip_index}]}
    ssh gcmemb@$ip /bin/bash << EOF
    if [[ $lip == $ip ]]; then
      sudo -- sh -c "echo '127.0.0.1 node${ip_index}' >> /etc/cloud/templates/hosts.debian.tmpl"
    else
      sudo -- sh -c "echo '${lip} node${ip_index}' >> /etc/cloud/templates/hosts.debian.tmpl"
    fi
EOF
  done
done

ssh gcmemb@${gluster_ips[0]} /bin/bash << EOF
  for ip_index in ${!gluster_ips[*]}
  do
    sudo gluster peer probe node\$ip_index
  done
  sudo gluster volume create kube_gluster_0 replica 3 transport tcp $gluster_nodes_export force
  sudo gluster volume start kube_gluster_0
EOF
