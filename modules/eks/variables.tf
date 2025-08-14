# variable "cluster_name" {
#   description = "EKS Cluster name"
#   type        = string
# }

variable "vpc_id" {
  description = "VPC ID where EKS cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of subnet IDs for EKS"
  type        = list(string)
}

variable "subnet_ids" {
  type        = list(string)
}

variable "karpenter_node_role" {
  type = string
}
