output "cluster_name" {
  value = aws_eks_cluster.opsfleet_cluster.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.opsfleet_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.opsfleet_cluster.certificate_authority[0].data
}
