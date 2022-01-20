#!/bin/bash
sudo virsh net-dhcp-leases kube | awk \
	"
	FNR > 2 {print \$6, \$5}
	" \
	| awk "NF" \
	| awk -F"/" "{print \$1\",\"}"
