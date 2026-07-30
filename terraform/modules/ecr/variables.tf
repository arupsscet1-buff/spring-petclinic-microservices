variable "repositories" {
  description = "List of ECR repositories"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}