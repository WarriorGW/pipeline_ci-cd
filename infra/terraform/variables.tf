# infra/terraform/variables.tf
variable "region" { type = string; default = "us-east-1" }
variable "cluster_name" { type = string; default = "practica2-eks" }
variable "node_group_desired_capacity" { type = number; default = 2 }
variable "node_instance_type" { type = string; default = "t3.medium" }
variable "vpc_id" { type = string; default = "" } # optional
