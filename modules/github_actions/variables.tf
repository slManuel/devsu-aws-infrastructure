variable "project_name" {
  description = "Prefijo de los recursos IAM para publicar la imagen de la API."
  type        = string
}

variable "github_owner" {
  description = "Usuario u organización propietaria del repositorio GitHub de la API."
  type        = string
}

variable "github_owner_id" {
  description = "Identificador inmutable del usuario u organización de GitHub."
  type        = string
}

variable "api_repository_name" {
  description = "Nombre del repositorio GitHub de la API."
  type        = string
}

variable "api_repository_id" {
  description = "Identificador inmutable del repositorio GitHub de la API."
  type        = string
}

variable "api_ecr_repository_arn" {
  description = "ARN del repositorio ECR exclusivo de la API."
  type        = string
}

variable "api_eks_cluster_arn" {
  description = "ARN del único clúster EKS al que el workflow de la API puede conectarse."
  type        = string
}

variable "tags" {
  description = "Etiquetas aplicadas a los recursos IAM."
  type        = map(string)
  default     = {}
}
