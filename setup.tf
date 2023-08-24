terraform {
  required_version = "~> 1.4"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.0"
    }
    helm = {
      source = "hashicorp/helm"
      #version = "2.5.1"
      version = "~> 2.10"
    }
    http = {
      source = "hashicorp/http"
      #version = "2.1.0"
      version = "~> 3.3"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.23"
    } 
  }
}
provider "aws" {
    #profile = "marcintegra"
    region = var.region
}
