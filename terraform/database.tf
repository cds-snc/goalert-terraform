resource "aws_db_subnet_group" "goalert" {
  name       = "goalert-${var.env}"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(local.common_tags, { Name = "goalert-db-${var.env}" })
}

resource "aws_security_group" "goalert_db" {
  description = "GoAlert Aurora PostgreSQL, allow inbound from app layer"
  name        = "goalert-db-${var.env}"
  vpc_id      = aws_vpc.goalert.id

  tags = merge(local.common_tags, { Name = "goalert-db-${var.env}" })
}

resource "aws_rds_cluster" "goalert" {
  cluster_identifier     = "goalert-${var.env}"
  engine                 = "aurora-postgresql"
  engine_version         = "16.6"
  database_name          = "goalert"
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.goalert.name
  vpc_security_group_ids = [aws_security_group.goalert_db.id]

  serverlessv2_scaling_configuration {
    min_capacity             = 0   
    max_capacity             = 2
    seconds_until_auto_pause = 300
  }

  storage_encrypted       = true
  backup_retention_period = 7
  skip_final_snapshot     = var.env == "staging" ? true : false

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "goalert" {
  cluster_identifier = aws_rds_cluster.goalert.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.goalert.engine
  engine_version     = aws_rds_cluster.goalert.engine_version

  tags = local.common_tags
}

output "db_endpoint" {
  description = "Aurora cluster writer endpoint — used in the GoAlert DB URL"
  value       = aws_rds_cluster.goalert.endpoint
}