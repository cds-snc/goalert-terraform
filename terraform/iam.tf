data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "goalert_lambda" {
  name               = "goalert-lambda-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "goalert_lambda_vpc" {
  role       = aws_iam_role.goalert_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

output "goalert_lambda_role_arn" {
  description = "ARN of the GoAlert Lambda execution role"
  value       = aws_iam_role.goalert_lambda.arn
}

