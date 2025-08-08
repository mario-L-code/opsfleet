variable "cluster_name" {
    type = string
}

variable "provider_arn" {
    type = string
}

variable "cluster_endpoint" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "subnet_ids" {
  type = list(string)
}