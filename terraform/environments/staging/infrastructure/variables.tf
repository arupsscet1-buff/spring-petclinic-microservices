variable "aws_region" {
    type = string
}

variable "environment" {
    type = string
}

variable "cidr_block" {
    type = string
}

variable "instance_type" {
    type = string
}

variable "key_name" {
    type = string
}

variable "instance_count" {
    type = number
    default = 1
}

variable "ecr_repositories" {
  type = list(string)
}