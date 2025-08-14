module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.34.0"

  role_name                           = "karpenter-controller-${var.cluster_name}"
  role_description                    = "IAM role for Karpenter controller service account"
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
  name = "karpenter-node-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
    "kubernetes.io/cluster/opsfleet" = "owned"
  }
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

resource "aws_iam_role_policy_attachment" "worker_node_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2SpotPolicy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "karpenter-node-instance-profile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}

resource "null_resource" "verify_crds" {
  provisioner "local-exec" {
    command = <<EOT
      export AWS_PROFILE=mike
      until kubectl get crd nodepools.karpenter.sh >/dev/null 2>&1 && kubectl get crd ec2nodeclasses.karpenter.k8s.aws >/dev/null 2>&1 && kubectl get crd nodeclaims.karpenter.sh >/dev/null 2>&1; do
        echo "Waiting for Karpenter CRDs to be available..."
        sleep 5
      done
      echo "Karpenter CRDs are available."
    EOT
  }
}

resource "helm_release" "karpenter" {
  timeout = 75
  name = "karpenter"
  namespace = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart = "karpenter"
  version = "1.6.1"
  skip_crds = true
  create_namespace = true

  depends_on = [
    module.karpenter_irsa,
    aws_iam_instance_profile.karpenter_node_instance_profile,
    null_resource.verify_crds
  ]

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
      name  = "aws.defaultInstanceProfile"
      value = aws_iam_instance_profile.karpenter_node_instance_profile.name
    }
  ]
}