variable "aws_region" {
  description = "Región donde existe o se creará el repositorio ECR de la API."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefijo de los nombres de recursos del proyecto."
  type        = string
  default     = "devsu"
}

variable "environment" {
  description = "Entorno utilizado en nombres y etiquetas."
  type        = string
  default     = "dev"
}

variable "github_owner" {
  description = "Cuenta u organización GitHub propietaria de los repositorios."
  type        = string
  default     = "slManuel"
}

variable "github_owner_id" {
  description = "Identificador inmutable del usuario u organización GitHub propietaria."
  type        = string
  default     = "65916668"
}

variable "api_repository_name" {
  description = "Nombre del repositorio GitHub de la API Python."
  type        = string
  default     = "devsu-python-api"
}

variable "api_repository_id" {
  description = "Identificador inmutable del repositorio GitHub de la API."
  type        = string
  default     = "1450754359"

  validation {
    condition     = can(regex("^[0-9]+$", var.api_repository_id))
    error_message = "Indica el ID numérico del repositorio GitHub de la API."
  }
}

variable "infra_repository_name" {
  description = "Nombre del repositorio GitHub de infraestructura Terraform."
  type        = string
  default     = "devsu-aws-infrastructure"
}

variable "infra_repository_id" {
  description = "Identificador numérico e inmutable del repositorio de infraestructura."
  type        = string
  default     = "1450754407"

  validation {
    condition     = can(regex("^[0-9]+$", var.infra_repository_id))
    error_message = "Indica el ID numérico del repositorio GitHub de infraestructura."
  }
}

variable "tf_state_bucket_name" {
  description = "Bucket S3 existente que contiene los estados remotos de Terraform."
  type        = string
  default     = "devsu-tfstate-297196566401-us-east-2-20261110"
}
