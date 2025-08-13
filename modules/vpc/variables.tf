variable "cluster_name" {
    type = string
}

# variable "aws_region" {
#     type = string
# }

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
  default     = null # Set to null for new VPC creation
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node group"
  type        = list(string)
  default     = [] # Set to empty list for new subnets
}