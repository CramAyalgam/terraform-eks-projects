module "vpc" {
  source = "./modules/vpc"

  prefix_tag_name = var.prefix_tag_name

  region = var.region
  cluster_name = var.cluster_name
  vpc_name = var.vpc_name
  vpc_cidr_block = "${var.vpc_cidr_range}.0.0/16"

  public_subnets = {
    a: "${var.vpc_cidr_range}.1.0/24"
    b: "${var.vpc_cidr_range}.2.0/24"
  }
  private_subnets = {
    a: "${var.vpc_cidr_range}.11.0/24"
    b: "${var.vpc_cidr_range}.12.0/24"
  }
  rds_subnets = {
    a: "${var.vpc_cidr_range}.21.0/24"
    b: "${var.vpc_cidr_range}.23.0/24"
  }
}

# module "eks_bastion" {
#   source = "./modules/bastion"

#   prefix_tag_name = var.prefix_tag_name

#   key_pair = var.key_pair
#   ami = var.ami
#   subnet_id = "${module.vpc.public_subnet_ids[0]}"
#   vpc_id = module.vpc.vpc_id

# }

module "eks" {
  source = "./modules/eks"
  cluster_name = var.cluster_name
  cluster_version = "1.27"

  prefix_tag_name = var.prefix_tag_name
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id = module.vpc.vpc_id

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_service_ipv4_cidr = "172.20.0.0/16"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true

  node_group_name = "marc-eks-ng"
  key_pair = var.key_pair

  region = var.region

}


