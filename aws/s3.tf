resource "aws_s3_bucket" "backup" {
  bucket = "${var.aws_prefix}-backup"

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}
