resource "aws_security_group" "goalert_alb" {
  name        = "goalert-alb-${var.env}"
  description = "GoAlert ALB - allow HTTP inbound from internet"
  vpc_id      = aws_vpc.goalert.id

  tags = merge(local.common_tags, { Name = "goalert-alb-${var.env}" })
}

resource "aws_vpc_security_group_ingress_rule" "goalert_alb_http" {
  security_group_id = aws_security_group.goalert_alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "goalert_alb_egress_all" {
  security_group_id = aws_security_group.goalert_alb.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "goalert_ecs" {
  name        = "goalert-ecs-${var.env}"
  description = "GoAlert ECS task - allow inbound from ALB only"
  vpc_id      = aws_vpc.goalert.id

  tags = merge(local.common_tags, { Name = "goalert-ecs-${var.env}" })
}

resource "aws_vpc_security_group_ingress_rule" "goalert_ecs_from_alb" {
  security_group_id            = aws_security_group.goalert_ecs.id
  description                  = "GoAlert port 8081 from ALB"
  ip_protocol                  = "tcp"
  from_port                    = 8081
  to_port                      = 8081
  referenced_security_group_id = aws_security_group.goalert_alb.id
}

resource "aws_vpc_security_group_egress_rule" "goalert_ecs_egress_all" {
  security_group_id = aws_security_group.goalert_ecs.id
  description       = "Allow all outbound (Aurora + ECR via NAT)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "goalert_db_from_ecs" {
  security_group_id            = aws_security_group.goalert_db.id
  description                  = "Postgres from GoAlert ECS task"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.goalert_ecs.id
}

resource "aws_lb" "goalert" {
  name               = "goalert-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.goalert_alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = merge(local.common_tags, { Name = "goalert-alb-${var.env}" })
}

resource "aws_lb_target_group" "goalert" {
  name        = "goalert-${var.env}"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.goalert.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "8081"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
    matcher             = "200"
  }

  tags = merge(local.common_tags, { Name = "goalert-tg-${var.env}" })
}

resource "aws_lb_listener" "goalert_http" {
  load_balancer_arn = aws_lb.goalert.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.goalert.arn
  }
}

resource "aws_cloudwatch_log_group" "goalert_ecs" {
  name              = "/ecs/goalert-${var.env}"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_ecs_cluster" "goalert" {
  name = "goalert-${var.env}"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "goalert" {
  family                   = "goalert-${var.env}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.goalert_task_execution.arn
  task_role_arn            = aws_iam_role.goalert_task.arn

  container_definitions = jsonencode([{
    name  = "goalert"
    image = "${aws_ecr_repository.goalert.repository_url}:latest"
    portMappings = [{
      containerPort = 8081
      protocol      = "tcp"
    }]
    environment = [
      { name = "GOALERT_DB_URL",              value = "postgres://${var.db_username}:${var.db_password}@${aws_rds_cluster.goalert.endpoint}:5432/goalert" },
      { name = "GOALERT_DATA_ENCRYPTION_KEY", value = var.goalert_encryption_key },
      { name = "GOALERT_PUBLIC_URL",          value = var.public_url },
      { name = "GOALERT_LISTEN",              value = ":8081" },
      { name = "GOALERT_LOG_FORMAT",          value = "json" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.goalert_ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = local.common_tags
}

resource "aws_ecs_service" "goalert" {
  name            = "goalert-${var.env}"
  cluster         = aws_ecs_cluster.goalert.id
  task_definition = aws_ecs_task_definition.goalert.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.goalert_ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.goalert.arn
    container_name   = "goalert"
    container_port   = 8081
  }

  depends_on = [aws_lb_listener.goalert_http]

  tags = local.common_tags
}

output "alb_dns_name" {
  description = "ALB DNS name — direct access before CloudFront is configured"
  value       = aws_lb.goalert.dns_name
}
