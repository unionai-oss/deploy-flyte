resource "aws_cloudwatch_log_group" "flyte_log_group" {
  name = "/${local.name_prefix}/kubernetes"

  tags = {
    terraform = "true"
  }
   lifecycle {
    ignore_changes = [name]
  }
}