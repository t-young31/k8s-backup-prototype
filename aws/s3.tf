resource "aws_s3_bucket" "backup" {
  bucket = "${var.aws_prefix}-bucket"

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}
