# infra/terraform/main.tf
provider "aws" {
  region = var.region
}

# EKS cluster via terraform-aws-modules/eks
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = ">= 19.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnets         = null
  vpc_id          = var.vpc_id != "" ? var.vpc_id : null

  node_groups = {
    default = {
      desired_capacity = var.node_group_desired_capacity
      instance_type    = var.node_instance_type
    }
  }
}

# Kubeconfig output (path to be used by CI)
output "kubeconfig" {
  value = module.eks.kubeconfig
  sensitive = true
}

# Helm provider (uses kubeconfig from local env)
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Install nginx-ingress via Helm
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart      = "nginx-ingress"
  version    = "0.11.0"
  namespace  = "ingress-nginx"

  create_namespace = true

  values = [
    <<EOF
controller:
  service:
    type: LoadBalancer
EOF
  ]
}

# Create a namespace for the app using kubernetes provider (optional)
provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token = data.aws_eks_cluster_auth.cluster.token
}
resource "kubernetes_namespace" "app" {
  metadata { name = "app-prod" }
}
