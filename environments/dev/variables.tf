variable "aws_region" {
  description = "Región AWS para todos los recursos del entorno."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefijo legible que se añade a los nombres de recursos."
  type        = string
  default     = "devsu"
}

variable "environment" {
  description = "Nombre corto del entorno desplegado."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Bloque IPv4 de la VPC; debe permitir seis subredes /24."
  type        = string
  default     = "10.20.0.0/16"
}

variable "cluster_version" {
  description = "Versión menor de Kubernetes ofrecida por EKS en la región."
  type        = string
  default     = "1.37"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR de administración autorizados para el endpoint público del API de Kubernetes."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : cidr != "0.0.0.0/0"])
    error_message = "Indica al menos un CIDR de administración y no expongas el endpoint a 0.0.0.0/0."
  }
}

variable "postgres_engine_version" {
  description = "Versión PostgreSQL aprobada en la región; null usa el valor predeterminado de RDS."
  type        = string
  default     = null
  nullable    = true
}
