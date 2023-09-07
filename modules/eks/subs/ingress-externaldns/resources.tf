# HELM Provider
# provider "helm" {
#   kubernetes {
#     host                   = var.eks_endpoint
#     cluster_ca_certificate = base64decode(var.ca_data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }

provider "kubernetes" {
  host = var.eks_endpoint
  cluster_ca_certificate = base64decode(var.ca_data)
  token = data.aws_eks_cluster_auth.cluster.token
}

# Resource: Create External DNS IAM Policy 
resource "aws_iam_policy" "externaldns_iam_policy" {
  name        = "AllowExternalDNSUpdates"
  path        = "/"
  description = "External DNS IAM Policy"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
})
}

# Resource: Create IAM Role 
resource "aws_iam_role" "externaldns_iam_role" {
  name = "externaldns-iam-role"

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${var.aws_iam_openid_connect_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${var.aws_iam_openid_connect_provider_extract_from_arn}:aud": "sts.amazonaws.com",            
            "${var.aws_iam_openid_connect_provider_extract_from_arn}:sub": "system:serviceaccount:default:external-dns"
          }
        }        
      },
    ]
  })

  tags = {
    tag-key = "AllowExternalDNSUpdates"
  }
}

# Associate External DNS IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "externaldns_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.externaldns_iam_policy.arn 
  role       = aws_iam_role.externaldns_iam_role.name
}

resource "kubernetes_manifest" "serviceaccount_external_dns" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ServiceAccount"
    "metadata" = {
      "annotations" = {
        "eks.amazonaws.com/role-arn" = "${aws_iam_role.externaldns_iam_role.arn}"
      }
      "name" = "external-dns"
      "namespace" = "default"
    }
  }
}

resource "kubernetes_manifest" "clusterrole_external_dns" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRole"
    "metadata" = {
      "name" = "external-dns"
    }
    "rules" = [
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "services",
          "endpoints",
          "pods",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
      {
        "apiGroups" = [
          "extensions",
          "networking.k8s.io",
        ]
        "resources" = [
          "ingresses",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "nodes",
        ]
        "verbs" = [
          "list",
          "watch",
        ]
      },
      {
        "apiGroups" = [
          "",
        ]
        "resources" = [
          "endpoints",
        ]
        "verbs" = [
          "get",
          "watch",
          "list",
        ]
      },
    ]
  }
}

resource "kubernetes_manifest" "clusterrolebinding_external_dns_viewer" {
  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind" = "ClusterRoleBinding"
    "metadata" = {
      "name" = "external-dns-viewer"
    }
    "roleRef" = {
      "apiGroup" = "rbac.authorization.k8s.io"
      "kind" = "ClusterRole"
      "name" = "external-dns"
    }
    "subjects" = [
      {
        "kind" = "ServiceAccount"
        "name" = "external-dns"
        "namespace" = "default"
      },
    ]
  }
}

resource "kubernetes_manifest" "deployment_external_dns" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "name" = "external-dns"
      "namespace" = "default"
    }
    "spec" = {
      "selector" = {
        "matchLabels" = {
          "app" = "external-dns"
        }
      }
      "strategy" = {
        "type" = "Recreate"
      }
      "template" = {
        "metadata" = {
          "annotations" = {
            "iam.amazonaws.com/role" = "${aws_iam_role.externaldns_iam_role.arn}"
          }
          "labels" = {
            "app" = "external-dns"
          }
        }
        "spec" = {
          "containers" = [
            {
              "args" = [
                "--source=service",
                "--source=ingress",
                "--domain-filter=oncloud.ae",
                "--provider=aws",
                "--policy=sync",
                "--aws-zone-type=public",
                "--registry=txt",
                "--txt-owner-id=external-dns",
                "--txt-prefix=test",
              ]
              "image" = "k8s.gcr.io/external-dns/external-dns:v0.13.1"
              "name" = "external-dns"
            },
          ]
          "securityContext" = {
            "fsGroup" = 65534
          }
          "serviceAccountName" = "external-dns"
        }
      }
    }
  }
}

#Resource: Helm Release 
# resource "helm_release" "external_dns" {
#   depends_on = [aws_iam_role.externaldns_iam_role]            
#   name       = "external-dns"
#   #version    = "0.13.1"
#   repository = "https://kubernetes-sigs.github.io/external-dns/"
#   chart      = "external-dns"

#   namespace = "default"     

#   set {
#     name = "image.repository"
#     #value = "k8s.gcr.io/external-dns/external-dns" 
#     value = "registry.k8s.io/external-dns/external-dns"
#   }

#   set {
#     name = "image.tag"
#     #value = "k8s.gcr.io/external-dns/external-dns" 
#     value = "v0.13.1"
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "external-dns"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = "${aws_iam_role.externaldns_iam_role.arn}"
#   }

#   set {
#     name  = "provider" # Default is aws (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
#     value = "aws"
#   }    

#   set {
#     name  = "policy" # Default is "upsert-only" which means DNS records will not get deleted even equivalent Ingress resources are deleted (https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
#     value = "sync"   # "sync" will ensure that when ingress resource is deleted, equivalent DNS record in Route53 will get deleted
#   }

#   set {
#     name  = "txtprefix"
#     value = "test"
#   }

#   set {
#     name  = "txtOwnerId"
#     value = "external-dns"
#   }

#   set {
#     name  = "source"
#     value = "service"
#   }

#   set {
#     name  = "source"
#     value = "ingress"
#   }

#   set {
#     name  = "domainFilters"
#     value = "{oncloud.ae}"
#   }
# }