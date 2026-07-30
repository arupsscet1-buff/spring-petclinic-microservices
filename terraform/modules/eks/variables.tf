variable "eks_name" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the EKS cluster control plane (typically private subnets)"
}

variable "environment" {
  type = string
}