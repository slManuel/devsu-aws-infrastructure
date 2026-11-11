variable "name" {
  description = "Nombre del secreto de configuración privada que utilizará la API."
  type        = string
}

variable "tags" {
  description = "Etiquetas compartidas."
  type        = map(string)
  default     = {}
}
