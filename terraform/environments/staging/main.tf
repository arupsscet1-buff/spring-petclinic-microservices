provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "spring-petclinic"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id, "--region", var.aws_region]
    }
  }
}

data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = var.cidr_block
}

module "vpc" {
  source = "../../modules/vpc"

  environment     = var.environment
  cidr_block      = local.vpc_cidr
  public_azs      = local.azs
  private_azs     = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
}

module "eks" {
  source = "../../modules/eks"

  eks_name        = "${var.environment}-cluster"
  node_group_name = "${var.environment}-nodeGroup"
  subnet_ids      = module.vpc.private_subnet_ids
  environment     = var.environment
}

module "ec2" {
  source = "../../modules/ec2"

  environment    = var.environment
  instance_type  = var.instance_type
  subnet_id      = module.vpc.public_subnet_ids[0]
  vpc_id         = module.vpc.vpc_id
  key_name       = var.key_name
  instance_count = var.instance_count
}

module "alb-controller" {
    source = "../../modules/alb-controller"

    cluster_name = module.eks.cluster_id
    environment = var.environment
    oidc_provider_arn = module.eks.oidc_provider_arn
    oidc_provider_url = module.eks.oidc_provider_url
    vpc_id = module.vpc.vpc_id

    depends_on = [ module.eks ]
}

module "ecr" {
  source = "../../modules/ecr"

  repositories = var.ecr_repositories
}