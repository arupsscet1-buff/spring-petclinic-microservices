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

data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}

provider "helm" {
  kubernetes {
    host = data.terraform_remote_state.infra.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(
      data.terraform_remote_state.infra.outputs.cluster_certificate_authority_data
    )
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.terraform_remote_state.infra.outputs.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

module "alb-controller" {
  source = "../../modules/alb-controller"

  cluster_name = data.terraform_remote_state.infra.outputs.cluster_name
  oidc_provider_arn = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  oidc_provider_url = data.terraform_remote_state.infra.outputs.oidc_provider_url
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
  environment = var.environment
}
