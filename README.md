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

The logs are in `/var/log/syslog`.

`sudo tail -f /var/log/syslog | grep tinyproxy`


## Pod outbound traffic

When you create a Pod the env variable are also injected to use the proxy.

Example
```
kubectl run --rm -ti --image=nicolaka/netshoot mypod /bin/bash
```

This is what you will see in the pod:

```
kubectl get pods mypod -o=jsonpath='{.spec.containers[0].env}' |jq
[
  {
    "name": "HTTP_PROXY",
    "value": "http://10.0.2.4:8888/"
  },
  {
    "name": "http_proxy",
    "value": "http://10.0.2.4:8888/"
  },
  {
    "name": "HTTPS_PROXY",
    "value": "http://10.0.2.4:8888/"
  },
  {
    "name": "https_proxy",
    "value": "http://10.0.2.4:8888/"
  },
  {
    "name": "NO_PROXY",
    "value": "127.0.0.1,localhost,192.168.0.0/16,konnectivity,10.0.0.0/8,169.254.169.254,myakscluster-0bvp19rq.hcp.westeurope.azmk8s.io,10.0.2.0/24,10.0.0.0/16,168.63.129.16"
  },
  {
    "name": "no_proxy",
    "value": "127.0.0.1,localhost,192.168.0.0/16,konnectivity,10.0.0.0/8,169.254.169.254,myakscluster-0bvp19rq.hcp.westeurope.azmk8s.io,10.0.2.0/24,10.0.0.0/16,168.63.129.16"
  }
]
```

To disable the injection of the proxy variables you can use the following annotation `"kubernetes.azure.com/no-http-proxy-vars":"true"`.

```
 kubectl run --rm -ti --image=nicolaka/netshoot  --overrides='{ "apiVersion": "v1", "metadata": {"annotations": { "kubernetes.azure.com/no-http-proxy-vars":"true" } } }' mypod /bin/bash
 ```
