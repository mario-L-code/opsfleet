resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"]
    description = "Allow nodes to communicate with EKS control plane"
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"]
    description = "Allow control plane to communicate with kubelet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name                    = "opsfleet-eks-sg"
    # "kubernetes.io/cluster/opsfleet-cluster" = "shared"
    # "kubernetes.io/cluster/opsfleet" = "shared"
    "kubernetes.io/cluster/opsfleet" = "owned"

  }
}

resource "aws_eks_cluster" "opsfleet_cluster" {
  name = "opsfleet"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.opsfleet_cluster_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = "opsfleet"
    "kubernetes.io/cluster/opsfleet" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_security_group.eks_cluster_sg
  ]
}

resource "aws_iam_role" "opsfleet_cluster_role" {
  name = "eks-cluster-opsfleet"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "opsfleet-eks-cluster-role"
    "kubernetes.io/cluster/opsfleet" = "owned"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.opsfleet_cluster_role.name
}

resource "aws_iam_role" "opsfleet_node_role" {
  name = "eks-node-opsfleet"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "opsfleet-eks-node-role"
    "kubernetes.io/cluster/opsfleet" = "owned"
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.opsfleet_node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.opsfleet_node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.opsfleet_node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.opsfleet_node_role.name
}

resource "aws_eks_node_group" "opsfleet_nodes" {
  cluster_name    = aws_eks_cluster.opsfleet_cluster.name
  node_group_name = "opsfleet-nodegroup"
  node_role_arn   = aws_iam_role.opsfleet_node_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  tags = {
    Name                    = "opsfleet-nodegroup"
    "karpenter.sh/discovery" = "opsfleet"
    "kubernetes.io/cluster/opsfleet" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNIPolicy,
    aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore
  ]
}

data "aws_eks_cluster" "opsfleet" {
  name = aws_eks_cluster.opsfleet_cluster.name
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url             = data.aws_eks_cluster.opsfleet.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = {
    Name = "opsfleet-eks-oidc"

  }
}