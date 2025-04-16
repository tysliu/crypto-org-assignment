provider "aws" {
  region = var.aws_region
  profile = "cryptoorg"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project = var.project_name
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"

  cluster_name    = "${var.project_name}-cluster"

  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    crypto_nodes = {
      desired_size = 1
      max_size     = 1
      min_size     = 0

      instance_types = ["m5.xlarge"]
      disk_size      = 100

      tags = {
        Project = var.project_name
      }
    }
  }

  tags = {
    Project = var.project_name
  }
}
