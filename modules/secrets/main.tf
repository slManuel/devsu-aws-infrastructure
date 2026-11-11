resource "aws_secretsmanager_secret" "api_runtime" {
  name                    = var.name
  description             = "Variables secretas de ejecución para la API Devsu; el valor se carga fuera de Terraform."
  recovery_window_in_days = 7

  tags = merge(var.tags, { Name = var.name })
}
