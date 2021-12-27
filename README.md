# Terraform Rancher Kubernetes Deployment
This repository contains bash scripts to deploy virtual machines and add them into rancher

To configure deployment:
- Install rancher server to your docker container
- Change `RANCHER_HOST` variable in `register-rancher.sh` (Line 20)
- Edit `main.tfvars` to your needs
- Start `./terraform-install.sh`

Everything here is a subject to change
Reasoning behind this repo is basically to store history of my attempts in creating personal cluster
(Many of which are forever erased)

You're free to use any of these! I hope these snippets of mine will help somebody
