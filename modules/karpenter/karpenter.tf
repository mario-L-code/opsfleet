module "karpenter_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name                           = "karpenter-controller"
  attach_karpenter_controller_policy = true
  karpenter_controller_cluster_name  = var.cluster_name

  oidc_providers = {
    main = {
      provider_arn                = var.provider_arn
      namespace_service_accounts  = ["karpenter:karpenter"]
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.34.0"

  create_namespace = true

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa.iam_role_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.eks.node_iam_instance_profile_name
  }

  set {
    name  = "settings.aws.subnetSelector"
    value = jsonencode({ "karpenter.sh/discovery" = var.cluster_name })
  }
}