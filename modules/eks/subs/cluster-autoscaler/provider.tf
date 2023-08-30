# HELM Provider
provider "helm" {
  kubernetes {
    host                   = var.eks_endpoint
    #cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    cluster_ca_certificate = base64decode(var.ca_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}