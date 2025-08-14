# EKS with Karpenter

This repository contains Terraform code to deploy an AWS EKS cluster with Karpenter for autoscaling, supporting both x86 and arm64 (Graviton) instances, including Spot instances for cost optimization. The cluster is deployed in a dedicated VPC.

## Prerequisites
- AWS CLI configured with credentials.
- Terraform >= 1.5.0.
- kubectl installed.
- Helm installed.

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/mario-L-code/opsfleet.git
   cd opsfleet
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Apply Terraform**:
   ```bash
   terraform apply
   ```

4. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name opsfleet 
   ```

## Running Pods on x86 or Graviton Instances
Karpenter provisions nodes based on pod requirements. It deploys x86 (`amd64`) or Graviton (`arm64`) instances, depending on the deployment requirements. 

Deployment YAML files are ready to go for both x86 and Graviton servers:
```bash
kubectl apply -f ./modules/karpenter/test-x86.yaml
kubectl apply -f ./modules/karpenter/test-graviton.yaml
```


### Verify Node Type
Check which nodes the pods are running on:
```bash
kubectl get pods -o wide
kubectl get nodes -o wide
```

Karpenter will provision `t3.medium` for x86 (`amd64`) and `t4g.medium` for Graviton (`arm64`), using Spot instances.

## Cleanup
```bash
terraform destroy
kubectl delete -f ./modules/karpenter/test-x86.yaml
kubectl delete -f ./modules/karpenter/test-graviton.yaml
```

## Important

- Extra CRDs were deployed to make Karpenter function. Self-signed cert manager and Karpenter CRDs
  ```bash
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.1/cert-manager.crds.yaml 
  kubectl apply -f ./karpenter/crds/. 
  ```
- This cluster is API auth only. Must add Karpenter and any extra IAM roles to access entries manually for access to cluster



## Extra considerations

- A Node Pool and Node Class yaml file was put into the Karpenter module if you need to change the server types.
Right now, only t3.medium and t4g.medium servers will deploy.

  ```bash
  kubectl apply -f ./module/karpenter/node-pool.yaml
  kubectl apply -f ./module/karpenter/ec2-node-class.yaml
  ```

