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

# Configure AWS cli
$env:AWS_ACCESS_KEY_ID = $config.aws_access_id
$env:AWS_SECRET_ACCESS_KEY = $config.aws_access_key 
$env:AWS_DEFAULT_REGION = $config.aws_region 

# Create key pair
if ($config.vm_k8s_instance_keypair_new) {
    # Register key pair on aws
    $publicKey = (Get-Content -Path "$path/../config/$($config.vm_k8s_instance_keypair_name).pub" ) | Out-String
    $null = aws ec2 import-key-pair --region $config.aws_region --key-name $config.vm_k8s_instance_keypair_name --public-key-material $publicKey

    Write-Host "Created keypair $($config.vm_k8s_instance_keypair_name) on aws account."
}

# Prepare CloudFormation template
if ($config.vm_k8s_subnet_id -ne $null) {
    Build-EnvTemplate -InputPath "$($path)/../templates/cloudformation_vm_k8s_existing_subnet.yml" -OutputPath "$($path)/../temp/cloudformation_vm_k8s.yml" -Params1 $config -Params2 $resources
} else {
    Build-EnvTemplate -InputPath "$($path)/../templates/cloudformation_vm_k8s_new_subnet.yml" -OutputPath "$($path)/../temp/cloudformation_vm_k8s.yml" -Params1 $config -Params2 $resources
}

# Create vm
Write-Host "Creating AWS EC2 instance..."
$stackName = "vm-k8s-$($config.env_name)"
aws cloudformation create-stack --region $config.aws_region --stack-name $stackName --template-body "file://$($path)/../temp/cloudformation_vm_k8s.yml"

# Check for error
if ($LastExitCode -ne 0) {
    Write-Error "Can't create cloudformation stack $stackName. Watch logs above or check aws console and make sure it doesn't exists."
}

# Wait until stack creation is completed
Write-Host "Waiting for AWS EC2 instance to be created. It may take up to 10 minutes..."
aws cloudformation wait stack-create-complete --region $config.aws_region --stack-name $stackName

# Check for error
if ($LastExitCode -ne 0) {
    Write-Error "Can't create vm resources. Watch logs above or AWS CloudFormation stack $stackName events."
} else {
    Write-Host "Virtual machine created."
}

Write-Host "Get describe for created instance."
$out = (aws cloudformation describe-stacks --region $config.aws_region --stack-name $stackName  | ConvertFrom-Json) 

# Check for error
if ($LastExitCode -ne 0) {
    Write-Error "Can't get describe of stack $stackName"
} else {
    Write-Host "Received the describe of stack $stackName ."
}

Write-Host "Resource handling"
$outputs = ConvertOutputToResources -Outputs $out.Stacks.Outputs

# Get output resources
$resources.vm_k8s_private_ip = $outputs.PrivateIp.Trim()
$resources.vm_k8s_public_ip = $outputs.PublicIp.Trim()
$resources.vm_k8s_id = $outputs.InstanceId
$resources.vm_k8s_sg_id = $outputs.VMK8SSecurityGroupId

# Open access to allowed IP addresses if required
foreach ($cidr in $config.vm_k8s_ssh_allowed_cidr_blocks) {
    # Add ip to db security group 
    aws ec2 authorize-security-group-ingress `
        --group-id $resources.vm_k8s_sg_id `
        --protocol tcp `
        --port 22 `
        --cidr $cidr
    
    if ($LastExitCode -eq 0) {
        Write-Host "Opened port 22 on virtual machine for '$cidr'"
    }
}

# Write AWS EC2 resources
Write-EnvResources -Path $ConfigPath -Resources $resources

Write-Host "Resources Saved"
