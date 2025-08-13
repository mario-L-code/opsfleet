variable "cluster_name" {
    type = string
    # default = "opsfleet-cluster"
}

variable "provider_arn" {
    type = string
}

variable "cluster_endpoint" {
    type = string
    # default = "https://9FF20B4FCBFAAD616958C0499E937F65.gr7.us-east-1.eks.amazonaws.com"
}

variable "vpc_id" {
    type = string
}

# variable "subnet_ids" {
#   type = list(string)
# }

# variable "node_iam_instance_profile_name" {
#     type = string
# }
