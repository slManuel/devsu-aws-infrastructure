output "endpoint" {
  description = "Hostname privado de la instancia PostgreSQL."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Puerto PostgreSQL."
  value       = aws_db_instance.this.port
}

output "master_secret_arn" {
  description = "ARN del secreto cuyo valor contiene la contraseña administrada por RDS."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}
