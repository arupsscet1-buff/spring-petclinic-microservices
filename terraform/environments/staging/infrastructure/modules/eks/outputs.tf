output "cluster_id" {
  description = "EKS cluster name/ID"
  value       = aws_eks_cluster.example.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.example.arn
}

output "cluster_endpoint" {
  description = "API server endpoint for kubectl/CI-CD access"
  value       = aws_eks_cluster.example.endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = aws_eks_cluster.example.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA cert data, needed for kubeconfig / provider auth"
  value       = aws_eks_cluster.example.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Cluster's primary security group, needed if other resources (e.g. bastion, CI runners) need to be allowed to reach the API server"
  value       = aws_eks_cluster.example.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider, needed by any future IRSA role (e.g. ALB controller, EBS CSI, cluster-autoscaler)"
  value       = aws_iam_openid_connect_provider.example.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix, needed in IRSA trust policy conditions"
  value       = replace(aws_iam_openid_connect_provider.example.url, "https://", "")
}

output "node_group_id" {
  description = "Node group identifier"
  value       = aws_eks_node_group.example.id
}

output "node_role_arn" {
  description = "IAM role ARN used by worker nodes, useful if other AWS resources need to trust/allow this role (e.g. an S3 bucket policy, KMS key policy)"
  value       = aws_iam_role.node.arn
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN used by the EKS control plane itself"
  value       = aws_iam_role.cluster.arn
}

output "access_entry_id" {
  value = aws_eks_access_entry.admin.id
}