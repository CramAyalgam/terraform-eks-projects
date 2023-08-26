# VPC Input Variables

# VPC Name
variable "vpc_name" {
  description = "VPC Name"
  type = string 
  default = "myvpc"
}

#Prefix
variable "prefix_tag_name" {
  type = string 
}

# # VPC CIDR Range
# variable "vpc_cidr_range" {
#   description = "VPC CIDR range"
#   type = string 
# }

# VPC CIDR Block
variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type = string 
}

variable "region" {
  type = string
}

variable "public_subnets" {
  type = map(string)
}

variable "private_subnets" {
  type = map(string)
}

# variable "rds_subnets" {
#   type = map(string)
# }

variable "cluster_name" {
  type = string
}
