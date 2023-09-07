# # Helm Release Outputs
# output "externaldns_helm_metadata" {
#   description = "Metadata Block outlining status of the deployed release."
#   value = helm_release.external_dns.metadata
# }

output "externaldns_iam_role_arn" {
  description = "External DNS IAM Role ARN"
  value = aws_iam_role.externaldns_iam_role.arn
}

output "externaldns_iam_policy_arn" {
  value = aws_iam_policy.externaldns_iam_policy.arn 
} 
