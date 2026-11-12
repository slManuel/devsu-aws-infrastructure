output "github_oidc_provider_arn" {
  description = "Proveedor OIDC de GitHub Actions creado en IAM."
  value       = module.github_actions.oidc_provider_arn
}

output "api_publisher_role_arn" {
  description = "ARN que debe configurarse como variable AWS_ROLE_ARN en el repositorio de la API."
  value       = module.github_actions.api_publisher_role_arn
}

output "infrastructure_deployer_role_arn" {
  description = "ARN del rol que debe usarse como variable AWS_INFRA_ROLE_ARN en GitHub."
  value       = module.github_actions.infrastructure_deployer_role_arn
}

output "api_ecr_repository_url" {
  description = "URI que debe configurarse como variable ECR_REPOSITORY_URI en el repositorio de la API."
  value       = local.api_ecr_repository_url
}
