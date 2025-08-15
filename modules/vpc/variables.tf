variable "cluster_name" {
    type = string
}


variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node group"
  type        = list(string)
  default     = [] # Set to empty list for new subnets
}