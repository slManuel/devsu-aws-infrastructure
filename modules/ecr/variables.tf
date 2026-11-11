variable "name" {
  description = "Nombre del repositorio privado de contenedores."
  type        = string
}

variable "tags" {
  description = "Etiquetas compartidas."
  type        = map(string)
  default     = {}
}
