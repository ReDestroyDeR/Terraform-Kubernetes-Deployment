#!/bin/bash
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8080:443 &
