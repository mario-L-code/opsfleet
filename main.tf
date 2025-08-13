module "vpc" {
  source       = "./modules/vpc"
  cluster_name = "opsfleet"
}

module "eks" {
  source       = "./modules/eks"
  vpc_id       = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
}



module "karpenter" {
  source       = "./modules/karpenter"
  cluster_name = module.eks.cluster_name
  provider_arn = module.eks.oidc_provider_arn
  cluster_endpoint = module.eks.cluster_endpoint
  vpc_id       = module.vpc.vpc_id
  # subnet_ids   = module.vpc.private_subnets
}
