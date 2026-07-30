variable "environment" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "AMI ID to launch. Leave null to auto-select latest Amazon Linux 2023."
  default     = null
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type        = string
  description = "Subnet to launch the instance into (from vpc module output)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID (from vpc module output), used for the security group"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access"
  default     = null
}

variable "user_data_path" {
  type        = string
  description = "Path to a user_data script template file"
  default     = null
}

variable "user_data_vars" {
  type        = map(string)
  description = "Variables to interpolate into the user_data template"
  default     = {}
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH in — keep tight, never 0.0.0.0/0 in real use"
  default     = []
}