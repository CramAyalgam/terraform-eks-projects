###########################################################
#          EKS Providers                 
###########################################################
provider "helm" {
  kubernetes {
    host                   = var.eks_endpoint
    #cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    cluster_ca_certificate = base64decode(var.ca_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host = var.eks_endpoint
  cluster_ca_certificate = base64decode(var.ca_data)
  token = data.aws_eks_cluster_auth.cluster.token
}


###########################################################
#          Kubernetes Ingress controller Manifest
###########################################################

# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = var.lb_name
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = var.lb_name
      # Ingress Core Settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" =  "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      "alb.ingress.kubernetes.io/healthcheck-path" =  "/index.html"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = 5
      "alb.ingress.kubernetes.io/success-codes" = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count" = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = 2
      ## SSL Settings
      # Option-1: Using Terraform jsonencode Function
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{"HTTPS" = 443}, {"HTTP" = 80}])
      # Option-2: Using Terraform File Function      
      #"alb.ingress.kubernetes.io/listen-ports" = file("${path.module}/listen-ports/listen-ports.json")   
      "alb.ingress.kubernetes.io/certificate-arn" =  var.acm_arn
      #"alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-1-2017-01" #Optional (Picks default if not used)    
      # SSL Redirect Setting
      "alb.ingress.kubernetes.io/ssl-redirect" = 443
    }    
  }

  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class            
    default_backend {
      service {
        name = kubernetes_service_v1.myapp3_np_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
    rule {
      http {
        path {
          backend {
            service {
              name = kubernetes_service_v1.myapp1_np_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/app1"
          path_type = "Prefix"
        }

        path {
          backend {
            service {
              name = kubernetes_service_v1.myapp2_np_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
          path = "/app2"
          path_type = "Prefix"
        }
      }
    }
  }
}


###########################################################
#   Kubernetes Sample App Deployment - Content Path Routing           
###########################################################

# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp1" {
  metadata {
    name = "app1-nginx-deployment"
    labels = {
      app = "app1-nginx"
    }
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app1-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app1-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kube-nginxapp1:1.0.0"
          name  = "app1-nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp2" {
  metadata {
    name = "app2-nginx-deployment"
    labels = {
      app = "app2-nginx"
    }
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app2-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app2-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kube-nginxapp2:1.0.0"
          name  = "app2-nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp3" {
  metadata {
    name = "app3-nginx-deployment"
    labels = {
      app = "app3-nginx"
    }
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "app3-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "app3-nginx"
        }
      }

      spec {
        container {
          image = "stacksimplify/kubenginx:1.0.0"
          name  = "app3-nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

###########################################################
# Kubernetes Node Port Service - Conten Path Routing
###########################################################

# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "myapp1_np_service" {
  metadata {
    name = "app1-nginx-nodeport-service"
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app1/index.html"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp1.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "myapp2_np_service" {
  metadata {
    name = "app2-nginx-nodeport-service"
    annotations = {
      "alb.ingress.kubernetes.io/healthcheck-path" = "/app2/index.html"
    }    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp2.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

resource "kubernetes_service_v1" "myapp3_np_service" {
  metadata {
    name = "app3-nginx-nodeport-service"
    annotations = {
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      #"alb.ingress.kubernetes.io/healthcheck-path" = "/index.html"
    }    
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp3.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}
