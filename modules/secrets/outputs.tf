output "api_runtime_secret_arn" {
  description = "ARN del contenedor de Secret Manager reservado para los valores de la API."
  value       = aws_secretsmanager_secret.api_runtime.arn
}
