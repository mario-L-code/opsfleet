# EKS with Karpenter POC

This repository contains Terraform code to deploy an AWS EKS cluster with Karpenter for autoscaling, supporting both x86 and arm64 (Graviton) instances, including Spot instances for cost optimization. The cluster is deployed in a dedicated VPC.

## Prerequisites
- AWS CLI configured with credentials (`mike` profile).
- Terraform >= 1.5.0.
- kubectl installed.
- Helm installed.

## Setup Instructions
1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Set Variables**:
   Create a `terraform.tfvars` file:
   ```hcl
   region = "us-east-1"
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Apply Terraform**:
   ```bash
   terraform apply
   ```

5. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name opsfleet --profile mike
   ```

6. **Apply Karpenter NodePool and EC2NodeClass**:
   ```bash
   kubectl apply -f modules/karpenter/nodepool.yaml
   kubectl apply -f modules/karpenter/ec2nodeclass.yaml
   ```

## Running Pods on x86 or Graviton Instances
Karpenter provisions nodes based on pod requirements. To target x86 (`amd64`) or Graviton (`arm64`) instances, use a `nodeSelector` in your pod/deployment manifest.

### Example: Run a Pod on x86
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: x86-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
  nodeSelector:
    kubernetes.io/arch: amd64
```

Apply:
```bash
kubectl apply -f x86-pod.yaml
```

### Example: Run a Pod on Graviton
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: graviton-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
  nodeSelector:
    kubernetes.io/arch: arm64
```

Apply:
```bash
kubectl apply -f graviton-pod.yaml
```

### Verify Node Type
Check which nodes the pods are running on:
```bash
kubectl get pods -o wide
kubectl get nodes -o wide
```

Karpenter will provision `t3.medium` or `t3.large` for x86 (`amd64`) and `t4g.medium` or `t4g.large` for Graviton (`arm64`), using Spot or On-Demand instances based on availability.

## Cleanup
```bash
terraform destroy
kubectl delete -f modules/karpenter/nodepool.yaml
kubectl delete -f modules/karpenter/ec2nodeclass.yaml
```

## Troubleshooting
- Check Karpenter pods:
  ```bash
  kubectl get pods -n karpenter
  kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
  ```
- Verify NodePool and EC2NodeClass:
  ```bash
  kubectl get nodepool default
  kubectl get ec2nodeclass default
  ```
- Check EC2 instances:
  - AWS Console: **EC2** > **Instances**