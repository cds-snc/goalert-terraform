# resource "aws_ssm_parameter" "goalert_db_url" {
#   name   = "/goalert/${var.env}/db_url"
#   type   = "SecureString"
#   value  = "postgres://${var.db_username}:${var.db_password}@${aws_rds_cluster.goalert.endpoint}/goalert"
#   key_id = aws_kms_key.goalert_ssm.arn
#   tags   = local.common_tags
# }

# resource "aws_ssm_parameter" "goalert_encryption_key" {
#   name   = "/goalert/${var.env}/data_encryption_key"
#   type   = "SecureString"
#   value  = var.goalert_encryption_key
#   key_id = aws_kms_key.goalert_ssm.arn
#   tags   = local.common_tags
# }

# output "ssm_db_url_arn" {
#   value = aws_ssm_parameter.goalert_db_url.arn
# }

# output "ssm_encryption_key_arn" {
#   value = aws_ssm_parameter.goalert_encryption_key.arn
# }
