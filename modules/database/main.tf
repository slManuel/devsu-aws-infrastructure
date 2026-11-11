resource "aws_security_group" "database" {
  name        = "${var.name}-sg"
  description = "Permite PostgreSQL únicamente desde los nodos del clúster EKS."
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL desde el security group administrado por EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-subnets" })
}

resource "aws_db_instance" "this" {
  identifier                  = var.name
  engine                      = "postgres"
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage_gib
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = "devsu"
  username                    = "devsu_admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period    = 7
  deletion_protection        = false
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.name}-final"
  delete_automated_backups   = true
  auto_minor_version_upgrade = false
  apply_immediately          = false

  tags = merge(var.tags, { Name = var.name })
}
