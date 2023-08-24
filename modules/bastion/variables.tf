
variable "ssh_allowed_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "prefix_tag_name" {
  type = string 
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"
}

variable "key_pair" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "tenancy" {
  type = string
  default = "host"
}

variable "vpc_id" {
  type = string
}


variable "ami" {
  type = string
}