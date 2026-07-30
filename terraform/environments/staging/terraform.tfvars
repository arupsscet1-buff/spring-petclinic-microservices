aws_region     = "ap-south-1"
environment    = "staging"
cidr_block     = "10.0.0.0/16"
instance_type  = "t3.large"
key_name       = "arupdops-mumbai"
instance_count = 1
ecr_repositories = [
  "spring-petclinic-config-server",
  "spring-petclinic-discovery-server",
  "spring-petclinic-api-gateway",
  "spring-petclinic-admin-server",
  "spring-petclinic-customers-service",
  "spring-petclinic-vets-service",
  "spring-petclinic-visits-service",
  "spring-petclinic-genai-service"
]