variable "name" {
  description = "Prefijo de nombres para los recursos de red."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR de la VPC, normalmente un bloque /16 privado."
  type        = string
}

variable "availability_zones" {
  description = "Exactamente dos zonas de disponibilidad distintas."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "La red requiere dos zonas de disponibilidad distintas."
  }
}

variable "tags" {
  description = "Etiquetas compartidas para recursos de red."
  type        = map(string)
  default     = {}
}
