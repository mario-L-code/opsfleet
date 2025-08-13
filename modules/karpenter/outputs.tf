output "karpenter_node_instance_profile_name" {
  value = aws_iam_instance_profile.karpenter_node_instance_profile.name
}

output "cluster_name" {
  value = var.cluster_name
}

output "cluster_endpoint" {
  value = var.cluster_endpoint
}
