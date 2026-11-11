output "cluster_name" {
  description = "Nombre del clúster EKS."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint del plano de control de Kubernetes."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Security group de EKS utilizado como origen para las reglas de PostgreSQL."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  description = "Rol del grupo administrado de nodos."
  value       = aws_iam_role.node.arn
}
