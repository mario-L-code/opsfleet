resource "aws_eks_cluster" "opsfleet_cluster" {
  name = "opsfleet-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.opsfleet_cluster_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  tags = {
    Name = "opsfleet-eks-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
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
      },
    ]
  })

  tags = {
    Name = "opsfleet-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.opsfleet_cluster_role.name
}
