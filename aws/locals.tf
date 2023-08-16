locals {
  tags = {
    Repo  = "k8s-backup-prototype"
    Owner = data.aws_caller_identity.current.arn
  }
}
