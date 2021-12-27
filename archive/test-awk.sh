#!/bin/bash
function inject_awk {
  local tmp=$(awk -v target=$1 'BEGIN { FS = "=" }; { if ($1 == target) { print $2 } }' ./main.tfvars)
  echo $tmp | if [[ $(wc -L) -eq 0 ]]; then echo $2; else echo $tmp; fi
}

inject_awk "hostname" "kubenode" # { default = "kubenode" }
