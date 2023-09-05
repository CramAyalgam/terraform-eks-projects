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

# Autoscaling Full Access
resource "aws_iam_role_policy_attachment" "eks-Autoscaling-Full-Access" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
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
    # Cluster Autoscaler Tags
    #"k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
    #"k8s.io/cluster-autoscaler/enabled" = "TRUE"
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
    # Cluster Autoscaler Tags
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled" = "TRUE"
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
#          EKS Load balancer                 
###########################################################

# Resource: Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "lbc_iam_policy" {
  name        = "${local.name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  #policy = data.http.lbc_iam_policy.body
  policy = file("modules/eks/iam-policy-controller.json")
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

module "ingress-controller" {
  source = "./subs/ingress-controller"

  vpc_id = var.vpc_id
  region = var.region

  eks_cluster_id = aws_eks_cluster.main.id

  lbc_iam_role_arn = aws_iam_role.lbc_iam_role.arn

  eks_endpoint = aws_eks_cluster.main.endpoint

  ca_data =aws_eks_cluster.main.certificate_authority[0].data
}

###########################################################
#          EKS Ingress Content Path Routing + SSL
###########################################################
module "content-path-routing" {
  source = "./subs/content-path-routing"

  lb_name = "ingress-cpr"

  acm_arn = var.acm_arn

  eks_cluster_id = aws_eks_cluster.main.id
  eks_endpoint = aws_eks_cluster.main.endpoint
  ca_data =aws_eks_cluster.main.certificate_authority[0].data
} 

###########################################################
#          EKS Cluster Auto Scaler
###########################################################

# module "cluster-autoscaler" {
#   source = "./subs/cluster-autoscaler"

# aws_iam_openid_connect_provider_arn = local.aws_iam_oidc_connect_provider_arn
# aws_iam_openid_connect_provider_extract_from_arn = local.aws_iam_oidc_connect_provider_extract_from_arn

# eks_cluster_id = aws_eks_cluster.main.id

# region = var.region

# prefix_tag_name = var.prefix_tag_name

# eks_endpoint = aws_eks_cluster.main.endpoint

# ca_data =aws_eks_cluster.main.certificate_authority[0].data

# }

###########################################################
#          EKS Ingress + External DNS
###########################################################

# module "ingress-externaldns" {
#   source = "./subs/ingress-externaldns"

#   aws_iam_openid_connect_provider_arn = local.aws_iam_oidc_connect_provider_arn
#   aws_iam_openid_connect_provider_extract_from_arn = local.aws_iam_oidc_connect_provider_extract_from_arn

#   eks_cluster_id = aws_eks_cluster.main.id
#   eks_cluster_name = aws_eks_cluster.main.name
#   region = var.region

#   prefix_tag_name = var.prefix_tag_name

#   eks_endpoint = aws_eks_cluster.main.endpoint

#   ca_data = aws_eks_cluster.main.certificate_authority[0].data

# }