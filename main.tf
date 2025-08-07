module "vpc" {
  source       = "./modules/vpc"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
}

module "eks" {
  source       = "./modules/eks"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}

module "karpenter" {
  source       = "./modules/karpenter"
  aws_region   = var.aws_region
  cluster_name = var.cluster_name

  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  eks          = module.eks
}
