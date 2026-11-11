variable "aws_region" {
  description = "Región donde se crea el bucket remoto de Terraform."
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Nombre globalmente único para el bucket de estado de Terraform."
  type        = string

  validation {
    condition     = length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63
    error_message = "El nombre del bucket debe tener entre 3 y 63 caracteres."
  }
}
