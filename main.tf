module "vpc" {
  source       = "./modules/vpc"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.public_subnets
}


# module "karpenter" {
#   source       = "./modules/karpenter"
#   cluster_name = var.cluster_name
#   provider_arn = module.eks.oidc_provider_arn
#   cluster_endpoint = module.eks.cluster_endpoint
#   vpc_id       = module.vpc.vpc_id
#   subnet_ids   = module.vpc.private_subnets
# }
