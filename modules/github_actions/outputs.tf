output "oidc_provider_arn" {
  description = "Proveedor OIDC de GitHub Actions registrado en IAM."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "api_publisher_role_arn" {
  description = "ARN del rol que el workflow de main de la API asume para publicar en ECR."
  value       = aws_iam_role.api_publisher.arn
}

output "infrastructure_deployer_role_arn" {
  description = "ARN del rol OIDC que el workflow de infraestructura asume desde la rama main."
  value       = aws_iam_role.infrastructure_deployer.arn
}
