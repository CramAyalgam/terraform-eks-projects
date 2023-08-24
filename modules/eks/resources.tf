###########################################################
#          EKS IAM Role for EKS Cluster                    
###########################################################

# Create IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix_tag_name}-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Associate IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

/*
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}
*/

###########################################################
#          EKS IAM Role for EKS Node Group                    
###########################################################

# IAM Role for EKS Node Group 
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "${var.prefix_tag_name}-eks-nodegroup-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodegroup_role.name
}

###########################################################
#          EKS Cluster                 
###########################################################

# Create AWS EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version = var.cluster_version

  vpc_config {
    subnet_ids = var.public_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs    
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }
  
  # Enable EKS Cluster Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

###########################################################
#          EKS Node Group - Public                 
###########################################################

# # Create AWS EKS Node Group - Public
# resource "aws_eks_node_group" "eks_ng_public" {
#   cluster_name    = aws_eks_cluster.main.name

#   node_group_name = "${var.node_group_name}-public"
#   node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
#   subnet_ids      = var.public_subnet_ids
#   #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)    
  
#   ami_type = "AL2_x86_64"
#   capacity_type = "ON_DEMAND"
#   disk_size = 20
#   instance_types = ["t3.medium"]
  
  
#   remote_access {
#     ec2_ssh_key = var.key_pair
#   }

#   scaling_config {
#     desired_size = 1
#     min_size     = 1    
#     max_size     = 2
#   }

#   # Desired max percentage of unavailable worker nodes during node group update.
#   update_config {
#     max_unavailable = 1    
#     #max_unavailable_percentage = 50    # ANY ONE TO USE
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
#   ] 

#   tags = {
#     Name = "Public-Node-Group"
#   }
# }

###########################################################
#          EKS Node Group - Private                 
###########################################################

# Create AWS EKS Node Group - Private

resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name    = aws_eks_cluster.main.name

  node_group_name = "${var.node_group_name}-private"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnet_ids
  #version = var.cluster_version #(Optional: Defaults to EKS Cluster Kubernetes version)    
  
  ami_type = "AL2_x86_64"  
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]
  
  
  remote_access {
    ec2_ssh_key = var.key_pair    
  }

  scaling_config {
    desired_size = 1
    min_size     = 1    
    max_size     = 2
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1    
    #max_unavailable_percentage = 50    # ANY ONE TO USE
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]  
  tags = {
    Name = "Private-Node-Group"
  }
}
###########################################################
#          EKS Providers                 
###########################################################


# Terraform Kubernetes Provider
provider "kubernetes" {
  host = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


###########################################################
#          EKS ConfigMap                 
###########################################################

# Resource: Kubernetes Config Map
resource "kubernetes_config_map_v1" "aws_auth" {
  depends_on = [ aws_eks_cluster.main  ]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
    #mapUsers = yamlencode(local.configmap_users)    
  }  
}

###########################################################
#          EKS OIDC                     
###########################################################

# Datasource: AWS Partition
# Use this data source to lookup information about the current AWS partition in which Terraform is working
data "aws_partition" "current" {}

# Resource: AWS IAM Open ID Connect Provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
    client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
    thumbprint_list = [var.eks_oidc_root_ca_thumbprint]
    url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

    tags = {
        Name = "${var.prefix_tag_name}-eks-irsa"
    }
#   tags = merge(
#     {
#       Name = "${var.cluster_name}-eks-irsa"
#     },
#     local.common_tags
#   )
}

# Sample Outputs for Reference
/*
aws_iam_openid_connect_provider_arn = "arn:aws:iam::180789647333:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/A9DED4A4FA341C2A5D985A260650F232"
aws_iam_openid_connect_provider_extract_from_arn = "oidc.eks.us-east-1.amazonaws.com/id/A9DED4A4FA341C2A5D985A260650F232"
*/

###########################################################
#          EKS IRSA                     
###########################################################


#data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_arn
#data.terraform_remote_state.eks.outputs.aws_iam_openid_connect_provider_extract_from_arn

# Resource: Create IAM Role and associate the EBS IAM Policy to it

resource "aws_iam_role" "irsa_iam_role" {
  name = "${var.prefix_tag_name}-irsa-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {            
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub": "system:serviceaccount:default:irsa-demo-sa"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "${var.prefix_tag_name}-irsa-iam-role"
  }
}

# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.irsa_iam_role.name
}




###########################################################
#          EKS Load balancer                 
###########################################################

# Resource: Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "${local.name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy = data.http.lbc_iam_policy.body
}

# Resource: Create IAM Role 
resource "aws_iam_role" "lbc_iam_role" {
  name = "${local.name}-lbc-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:aud": "sts.amazonaws.com",            
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "AWSLoadBalancerControllerIAMPolicy"
  }
}

# Associate Load Balanacer Controller IAM Policy to  IAM Role
resource "aws_iam_role_policy_attachment" "lbc_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.lbc_iam_policy.arn 
  role       = aws_iam_role.lbc_iam_role.name
}

###########################################################
#          EKS AWS Load Balancer Install
###########################################################

# Install AWS Load Balancer Controller using HELM

# Resource: Helm Release 
resource "helm_release" "loadbalancer_controller" {
  depends_on = [aws_iam_role.lbc_iam_role]            
  name       = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"     

  # Value changes based on your Region (Below is for me-central-1)
  set {
    name = "image.repository"
    value = "759879836304.dkr.ecr.me-central-1.amazonaws.com/amazon/aws-load-balancer-controller" 
    # Changes based on Region - This is for us-east-1 Additional Reference: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  }       

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.lbc_iam_role.arn}"
  }

  set {
    name  = "vpcId"
    value = "${var.vpc_id}"
  }  

  set {
    name  = "region"
    value = "${var.region}"
  }    

  set {
    name  = "clusterName"
    value = "${aws_eks_cluster.main.id}"
  }    
    
}

# Resource: Kubernetes Ingress Class
resource "kubernetes_ingress_class_v1" "ingress_class_default" {
  depends_on = [helm_release.loadbalancer_controller]
  metadata {
    name = "my-aws-ingress-class"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }  
  spec {
    controller = "ingress.k8s.aws/alb"
  }
}

## Additional Note
# 1. You can mark a particular IngressClass as the default for your cluster. 
# 2. Setting the ingressclass.kubernetes.io/is-default-class annotation to true on an IngressClass resource will ensure that new Ingresses without an ingressClassName field specified will be assigned this default IngressClass.  
# 3. Reference: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.3/guide/ingress/ingress_class/




###########################################################
#          EKS Kubernetes SA                     
###########################################################

# Resource: Kubernetes Service Account
resource "kubernetes_service_account_v1" "irsa_demo_sa" {
  depends_on = [ aws_iam_role_policy_attachment.irsa_iam_role_policy_attach ]
  metadata {
    name = "irsa-demo-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_iam_role.arn
      }
  }
}

###########################################################
#          Kubernetes Sample job
###########################################################
/*
Resource: Kubernetes Job

To verify jobs log
kubectl logs -f -l app=irsa-demo
kubectl get job
*/

# resource "kubernetes_job_v1" "irsa_demo" {
#   metadata {
#     name = "irsa-demo"
#   }
#   spec {
#     template {
#       metadata {
#         labels = {
#           app = "irsa-demo"
#         }
#       }
#       spec {
#         service_account_name = kubernetes_service_account_v1.irsa_demo_sa.metadata.0.name 
#         container {
#           name    = "irsa-demo"
#           image   = "amazon/aws-cli:latest"
#           args = ["s3", "ls"]
#           #args = ["ec2", "describe-instances", "--region", "${var.aws_region}"] # Should fail as we don't have access to EC2 Describe Instances for IAM Role
#         }
#         restart_policy = "Never"
#       }
#     }
#   }
# }
