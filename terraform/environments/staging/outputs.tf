# ---------- VPC ----------
output "vpc_id" {
  description = "VPC ID for this environment"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ---------- EKS ----------
output "eks_cluster_name" {
  description = "EKS cluster name — needed for `aws eks update-kubeconfig`"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 CA cert, needed for kubeconfig generation"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN — needed by any future IRSA-based module (ALB controller, autoscaler, etc.)"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "OIDC issuer URL (no https://) — needed in IRSA trust policy conditions"
  value       = module.eks.oidc_provider_url
}

# ---------- EC2 ----------
output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_public_ips" {
  description = "Public IPs of EC2 instances — useful for SSH"
  value       = module.ec2.public_ips
}