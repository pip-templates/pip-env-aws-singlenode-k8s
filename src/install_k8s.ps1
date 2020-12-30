#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$true, Position=0)]
    [string] $ConfigPath,
    [Alias("p")]
    [Parameter(Mandatory=$false, Position=1)]
    [string] $Prefix
)

$ErrorActionPreference = "Stop"

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../lib/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Prepare hosts file
$ansible_inventory = @("[masters]")
$ansible_inventory += "master ansible_host=$($resources.vm_k8s_public_ip) ansible_ssh_user=$($config.vm_k8s_instance_username) ansible_ssh_private_key_file=$path/../config/$($config.vm_k8s_instance_keypair_name)"

Set-Content -Path "$path/../temp/onprem_k8s_ansible_hosts" -Value $ansible_inventory

# Whitelist nodes
Build-EnvTemplate -InputPath "$($path)/../templates/ssh_keyscan_playbook.yml" -OutputPath "$($path)/../temp/ssh_keyscan_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/onprem_k8s_ansible_hosts" "$path/../temp/ssh_keyscan_playbook.yml"

# Install k8s dependecies
Build-EnvTemplate -InputPath "$($path)/../templates/onprem_k8s_dependencies_playbook.yml" -OutputPath "$($path)/../temp/onprem_k8s_dependencies_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/onprem_k8s_ansible_hosts" "$path/../temp/onprem_k8s_dependencies_playbook.yml"

# Init k8s cluster on master node
Build-EnvTemplate -InputPath "$($path)/../templates/onprem_k8s_master_playbook.yml" -OutputPath "$($path)/../temp/onprem_k8s_master_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/onprem_k8s_ansible_hosts" "$path/../temp/onprem_k8s_master_playbook.yml"

# Write k8s resources
$resources.k8s_type = "kubeadm"
$resources.k8s_inventory = $ansible_inventory

Write-EnvResources -Path $ConfigPath -Resources $resources
