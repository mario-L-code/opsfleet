module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  subnet_ids              = module.vpc.private_subnets
  vpc_id                  = module.vpc.vpc_id
  enable_irsa             = true
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}
