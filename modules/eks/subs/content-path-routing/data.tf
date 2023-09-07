# Datasource: 
data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_id
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}

