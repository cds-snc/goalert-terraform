# data "aws_caller_identity" "current" {}

# resource "aws_kms_key" "goalert_ssm" {
#   description         = "Encrypts GoAlert SSM SecureString parameters"
#   enable_key_rotation = true
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid       = "EnableIAMPermissions"
#       Effect    = "Allow"
#       Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
#       Action    = "kms:*"
#       Resource  = "*"
#     }]
#   })
#   tags = merge(local.common_tags, { Name = "goalert-ssm-${var.env}" })
# }

# resource "aws_kms_alias" "goalert_ssm" {
#   name          = "alias/goalert-ssm-${var.env}"
#   target_key_id = aws_kms_key.goalert_ssm.key_id
# }

