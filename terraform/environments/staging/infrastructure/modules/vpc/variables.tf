variable "cidr_block" { type = string }

variable "environment" { type = string }

variable "public_subnets" { type = list(string) }

variable "private_subnets" { type = list(string) }

variable "public_azs" { type = list(string) }

variable "private_azs" { type = list(string) }
