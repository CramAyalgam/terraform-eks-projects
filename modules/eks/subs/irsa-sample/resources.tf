

###########################################################
#          Kubernetes SA                     
###########################################################

# Resource: Kubernetes Service Account
# resource "kubernetes_service_account_v1" "irsa_demo_sa" {
#   depends_on = [ aws_iam_role_policy_attachment.irsa_iam_role_policy_attach ]
#   metadata {
#     name = "irsa-demo-sa"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_iam_role.arn
#       }
#   }
# }

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
