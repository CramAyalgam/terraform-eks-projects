# Bastion Outputs


# EKS Cluster Outputs
output "cluster_certificate_authority_data" {
  description = "Nested attribute containing certificate-authority-data for your cluster. This is the base64 encoded certificate data required to communicate with your cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

# # EKS Node Group Outputs - Public
# output "node_group_public_status" {
#   description = "Public Node Group status"
#   value       = module.eks.node_group_public_status
# }

# EKS Node Group Outputs - Private

output "node_group_private_id" {
  description = "Node Group 1 ID"
  value       = module.eks.node_group_private_id
}

output "node_group_private_arn" {
  description = "Private Node Group ARN"
  value       = module.eks.node_group_private_arn
}

output "node_group_private_status" {
  description = "Private Node Group status"
  value       = module.eks.node_group_private_status
}

output "node_group_private_version" {
  description = "Private Node Group Kubernetes Version"
  value       = module.eks.node_group_private_version
}
