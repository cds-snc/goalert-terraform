# ── ECS Task Execution Role (ECR pull + CloudWatch logs) ─────────────────────

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "goalert_task_execution" {
  name               = "goalert-task-execution-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "goalert_task_execution_policy" {
  role       = aws_iam_role.goalert_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── ECS Task Role (permissions granted to the running container) ──────────────

resource "aws_iam_role" "goalert_task" {
  name               = "goalert-task-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json

  tags = local.common_tags
}

output "goalert_task_execution_role_arn" {
  description = "ARN of the GoAlert ECS task execution role"
  value       = aws_iam_role.goalert_task_execution.arn
}

