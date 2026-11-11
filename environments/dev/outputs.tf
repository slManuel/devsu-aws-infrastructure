output "vpc_id" {
  description = "VPC del entorno."
  value       = module.network.vpc_id
}

output "ecr_repository_url" {
  description = "URI del repositorio privado para las imágenes de la API."
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Nombre del clúster EKS."
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "Endpoint PostgreSQL; la base no tiene IP pública."
  value       = module.database.endpoint
}

output "rds_master_secret_arn" {
  description = "ARN del secreto cuyo valor administra RDS; no imprime la contraseña."
  value       = module.database.master_secret_arn
  sensitive   = true
}

output "api_runtime_secret_arn" {
  description = "ARN del secreto de Secrets Manager que External Secrets sincroniza a Kubernetes."
  value       = module.secrets.api_runtime_secret_arn
}
