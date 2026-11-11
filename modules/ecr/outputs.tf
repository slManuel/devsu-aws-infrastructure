output "repository_url" {
  description = "URI de ECR para construir y publicar imágenes con una etiqueta git-<sha>."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN del repositorio de imágenes."
  value       = aws_ecr_repository.this.arn
}
