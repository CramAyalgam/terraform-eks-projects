# Datasource: 
data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_name
}

# Get AWS Account ID
data "aws_caller_identity" "current" {}

# data "aws_eks_cluster" "cluster" {
#   name = data.aws_eks_cluster_auth.cluster.name
# }