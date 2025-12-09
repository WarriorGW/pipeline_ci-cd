# infra/terraform/outputs.tf
output "cluster_name" {
  value = module.eks.cluster_id
}
output "kubeconfig_file" {
  value = module.eks.kubeconfig
  sensitive = true
}

