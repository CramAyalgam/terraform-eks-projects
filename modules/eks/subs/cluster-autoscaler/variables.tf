variable "prefix_tag_name" {
  type = string
}

variable "aws_iam_openid_connect_provider_arn" {
  type = string
}

variable "aws_iam_openid_connect_provider_extract_from_arn" {
  type = string
}

variable "eks_cluster_id" {
  type = string
}

variable "region" {
  type = string
}

variable "ca_data" {
  type = string
}

variable "eks_endpoint" {
  type = string
}
