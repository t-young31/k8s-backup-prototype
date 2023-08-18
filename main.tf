terraform {
  required_version = ">=1.2.0"
}

variable "aws_region" {}
variable "aws_prefix" {}
variable "cluster_name" {}

module "aws" {
  source     = "./aws"
  aws_region = var.aws_region
  aws_prefix = var.aws_prefix
}

module "local" {
  source       = "./local-k3d"
  cluster_name = var.cluster_name
}
