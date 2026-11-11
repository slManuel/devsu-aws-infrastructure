output "state_bucket_name" {
  description = "Bucket que almacena el estado remoto de Terraform."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_region" {
  description = "Región del bucket de estado remoto."
  value       = var.aws_region
}
