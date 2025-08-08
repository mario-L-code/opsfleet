module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name                           = "karpenter-controller"
  attach_karpenter_controller_policy = true
  karpenter_controller_cluster_name  = var.cluster_name

  oidc_providers = {
    main = {
      provider_arn               = var.provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_iam_role" "karpenter_node_role" {
  name = "karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEKSCNIPolicy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "karpenter-node-instance-profile"
  role = aws_iam_role.karpenter_node_role.name
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "0.16.3"

  create_namespace = true

  set = [
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = var.cluster_endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.karpenter_irsa.iam_role_arn
    },
    {
      name  = "settings.aws.defaultInstanceProfile"
      value = aws_iam_instance_profile.karpenter_node_instance_profile.name
    },
    {
      name  = "settings.aws.subnetSelector"
      value = jsonencode({ "karpenter.sh/discovery" = var.cluster_name })
    }
  ]
}

resource "kubernetes_manifest" "karpenter_provisioner" {
  depends_on = [helm_release.karpenter]
  manifest = {
    apiVersion = "karpenter.sh/v1alpha5"
    kind       = "Provisioner"
    metadata = {
      name = "default"
    }
    spec = {
      requirements = [
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = ["amd64", "arm64"]
        },
        # {
        #   key      = "node.kubernetes.io/instance-type"
        #   operator = "In"
        #   values = ["t3.micro", "t4g.micro"]

        # }
      ]
      provider = {
        subnetSelector = {
          "karpenter.sh/discovery" = var.cluster_name
        }
        securityGroupSelector = {
          "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        }
        instanceProfile = aws_iam_instance_profile.karpenter_node_instance_profile.name
        capacityType    = "spot"
      }
      ttlSecondsAfterEmpty = 30
    }
  }
}
