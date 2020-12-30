# Overview

This is a built-in module to environment [pip-templates-env-master](https://github.com/pip-templates/pip-templates-env-master). 
This module stores scripts for management aws single node kubernetes environment, also this module can be used for on-premises kubernetes environment.

# Usage

- Download this repository
- Copy *src* and *templates* folder to master template
- Add content of *.ps1.add* files to correspondent files from master template
- Add content of *config/config.k8s.json.add* to json config file from master template and set the required values

# Config parameters

Config variables description

| Variable | Default value | Description |
|----|----|---|
| env_type | on-premises | Type of environment |
| aws_access_id | XXX | AWS id for access resources |
| aws_access_key | XXX | AWS key for access resources |
| aws_region | us-east-1 | AWS region where resources will be created |
| env_name | pip-templates-stage | Name of environment |
| vpc | vpc-bb755cc1 | Amazon Virtual Private Cloud name where resources will be created |
| vm_k8s_subnet_id | | Use this property only if you have existing aws subnet in vpc and you want to use it for virtual mchine |
| vm_k8s_subnet_cidr | 172.31.100.0/28 | Virtual machine subnet address pool |
| vm_k8s_subnet_zone | us-east-1a | Virtual machine subnet zone |
| vm_k8s_ssh_allowed_cidr_blocks | [109.254.10.81/32, 46.219.209.174/32] | Virtual machine address pool allowed to SSH |
| vm_k8s_instance_type | t2.medium | Virtual machine vm type |
| vm_k8s_instance_keypair_new | true | Switch for creation new ssh key. If set to *true* - then key pair will be added to AWS |
| vm_k8s_instance_keypair_name | ecommerce | Virtual machine vm keypair |
| vm_k8s_instance_username | ubuntu | Virtual machine vm username |
| vm_k8s_instance_ami | ami-43a15f3e | Virtual machine vm aws image |
| vm_k8s_instance_username | piptemplatesadmin | Virtual machine username to ssh |
| onprem_k8s_network | 10.244.0.0/16 | Azure address pool for kubernetes cluster |
| onprem_kubernetes_cni_version | 0.6.0-00 | Kubernetes cni version to install |
| onprem_kubelet_version | 1.10.13-00 | Kubelet version to install |
| onprem_kubeadm_version | 1.10.13-00 | Kubeadm version to install |
| onprem_kubectl_version | 1.10.13-00 | Kubectl version to install |

# Testing enviroment
To test created environment after installation you can use *test_instances.ps1* script:
`
./src/test_instances.ps1 ./config/test_config.json
`
You have to create test config  before running *test_instances* script.
* Test config parameters

| Variable | Default value | Description |
|----|----|---| 
| username | piptemplatesadmin | Instance username |
| ssh_private_key_path | ./config/id_rsa | Path to private key used for ssh |
| nodes_ips | ["40.121.104.231", "40.121.133.1", "40.121.133.132"] | Public IP's of testing instances |
