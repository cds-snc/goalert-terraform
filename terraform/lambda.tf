resource "aws_security_group" "goalert_lambda" {
  name        = "goalert-lambda-${var.env}"
  description = "GoAlert Lambda - egress to Aurora and AWS APIs"
  vpc_id      = aws_vpc.goalert.id

  tags = merge(local.common_tags, { Name = "goalert-lambda-${var.env}" })
}

resource "aws_vpc_security_group_egress_rule" "goalert_lambda_egress_all" {
  security_group_id = aws_security_group.goalert_lambda.id
  description       = "Allow all outbound (Aurora + AWS APIs via NAT)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "goalert_db_from_lambda" {
  security_group_id            = aws_security_group.goalert_db.id
  description                  = "Postgres from GoAlert Lambda only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.goalert_lambda.id
}

resource "aws_lambda_function" "goalert" {
  function_name = "goalert-${var.env}"
  description   = "GoAlert on-call scheduler via Lambda Web Adapter"
  role          = aws_iam_role.goalert_lambda.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.goalert.repository_url}:latest"
  timeout       = 300
  memory_size   = 1024

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.goalert_lambda.id]
  }

  environment {
    variables = {
      GOALERT_DB_URL              = "postgres://${var.db_username}:${var.db_password}@${aws_rds_cluster.goalert.endpoint}:5432/goalert"
      GOALERT_DATA_ENCRYPTION_KEY = var.goalert_encryption_key
      GOALERT_PUBLIC_URL          = var.public_url
      GOALERT_LISTEN              = ":8081"
      GOALERT_LOG_FORMAT          = "json"
    }
  }

  tags = local.common_tags
}

resource "aws_lambda_function_url" "goalert" {
  function_name      = aws_lambda_function.goalert.function_name
  authorization_type = "NONE"
}

output "goalert_function_url" {
  description = "Direct Lambda URL"
  value       = aws_lambda_function_url.goalert.function_url
}

output "lambda_function_name" {
  description = "GoAlert Lambda function name"
  value       = aws_lambda_function.goalert.function_name
}
