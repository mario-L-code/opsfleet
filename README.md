# opsfleet# EKS with Karpenter, ARM64 and x86 Spot Support

This repo deploys an AWS EKS cluster using Terraform with:

- Managed node group for bootstrapping
- Karpenter for autoscaling Spot instances
- Multi-architecture (Graviton ARM64 + x86) pod support

---

## 🚀 How to Deploy

### Prerequisites

- AWS CLI with credentials configured
- Terraform 1.6+
- `kubectl`, `helm`
- An S3 bucket for Terraform state (optional)

### Steps

```bash
terraform init
terraform apply
