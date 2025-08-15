output "karpenter_node_instance_profile_name" {
  value = aws_iam_instance_profile.karpenter_node_instance_profile.name
}


output "cluster_endpoint" {
  value = var.cluster_endpoint
}

output "karpenter_node_role" {
  value = aws_iam_role.karpenter_node_role.arn
  
}