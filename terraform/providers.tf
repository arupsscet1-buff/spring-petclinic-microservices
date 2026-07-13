# =========================================================================
# KUBERNETES & HELM PROVIDERS CONFIGURATION
# =========================================================================

# 1. Configures native resources like kubernetes_service_account & kubernetes_storage_class_v1
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # Dynamically generates a fresh AWS token for cluster authentication
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "ap-south-1"]
  }
}

# 2. Configures helm_release blocks like your alb_controller
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", "ap-south-1"]
    }
  }
}
