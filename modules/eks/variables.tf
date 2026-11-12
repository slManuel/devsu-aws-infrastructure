variable "name" {
  description = "Nombre del clúster EKS."
  type        = string
}

variable "kubernetes_version" {
  description = "Versión menor de Kubernetes habilitada en la región."
  type        = string
}

variable "subnet_ids" {
  description = "Subredes privadas en dos AZ donde se alojan los nodos y ENI del clúster."
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR de administración permitido para el endpoint público de EKS."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : cidr != "0.0.0.0/0"])
    error_message = "Indica CIDR de administración restringidos; no uses 0.0.0.0/0."
  }
}

variable "node_instance_type" {
  description = "Tipo de instancia EC2 para el grupo administrado."
  type        = string
  default     = "t3a.small"
}

variable "node_count" {
  description = "Cantidad fija de nodos On-Demand del grupo administrado."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 2 && var.node_count <= 10
    error_message = "Para repartir dos réplicas entre AZ se requiere al menos dos nodos."
  }
}

variable "tags" {
  description = "Etiquetas compartidas."
  type        = map(string)
  default     = {}
}

variable "api_runtime_secret_arn" {
  description = "ARN exacto del secreto que External Secrets Operator puede leer."
  type        = string
}

variable "api_ecr_repository_arn" {
  description = "ARN del repositorio ECR del que los nodos pueden descargar imágenes."
  type        = string
}

variable "api_deployer_role_arn" {
  description = "Rol OIDC de GitHub Actions autorizado a desplegar la API en el namespace devsu."
  type        = string
}
