variable "name" {
  description = "Nombre base de la instancia PostgreSQL."
  type        = string
}

variable "subnet_ids" {
  description = "Subredes de datos privadas en al menos dos zonas de disponibilidad."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC donde existe el grupo administrado de EKS."
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Grupo de seguridad de EKS autorizado para conectarse a PostgreSQL."
  type        = string
}

variable "engine_version" {
  description = "Versión de PostgreSQL, opcional hasta consultar las versiones disponibles en la región."
  type        = string
  default     = null
  nullable    = true
}

variable "instance_class" {
  description = "Clase de instancia RDS para el entorno de desarrollo."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gib" {
  description = "Almacenamiento gp3 asignado a PostgreSQL en GiB."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Etiquetas compartidas."
  type        = map(string)
  default     = {}
}
