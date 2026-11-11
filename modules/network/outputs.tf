output "vpc_id" {
  description = "Identificador de la VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Subredes públicas para el ALB y la NAT Gateway."
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_app_subnet_ids" {
  description = "Subredes privadas para nodos EKS."
  value       = [for az in var.availability_zones : aws_subnet.private_app[az].id]
}

output "database_subnet_ids" {
  description = "Subredes privadas aisladas para RDS."
  value       = [for az in var.availability_zones : aws_subnet.database[az].id]
}
