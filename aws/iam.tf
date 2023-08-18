resource "aws_iam_user" "longhorn" {
  name = "${var.aws_prefix}-user-longhorn"
  path = "/"

  tags = local.tags
}

resource "aws_iam_access_key" "longhorn" {
  user = aws_iam_user.longhorn.name
}

data "aws_iam_policy_document" "longhorn" {

  statement {
    sid    = "GrantLonghornBackupstoreAccess0"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }
}

resource "aws_iam_user_policy" "longhorn" {
  name   = "${var.aws_prefix}-policy-longhorn"
  user   = aws_iam_user.longhorn.name
  policy = data.aws_iam_policy_document.longhorn.json
}
