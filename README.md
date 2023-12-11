# Create AKS cluster with HTTP Proxy for outbound traffic

This repo is a Terraform demo to deploy:
* AKS cluster with HTTP Proxy for outbound traffic
* A VM running tinyproxy to allow outbound traffic from the AKS cluster
* Network security group to allow outbound traffic from the AKS cluster to the tinyproxy VM
* Network security group to allow inbound traffic to the tinyproxy VM via SSH on port 2222


## Deploy the infrastructure

```
terraform init -upgrade
cp tfvars.example .tfvars
terraform apply -var-file=.tfvars
```

You will need later the public IP of the VM to login to the VM for troubleshooting.

Use the following commands to get the information:

```
az network public-ip list -o table
```

## Debugging

SSH to the VM on port 2222 with the public IP of the VM.

```
ssh -p 2222 azureuser@<publicIp>
```

The tinyproxy is running on port 8888.

The logs are in `/var/log/syslog`



