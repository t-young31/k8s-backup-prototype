locals {
  ec2_username = "ec2-user"
  ssh_key_name = "ec2_id_rsa"

  k3s_version = "v1.27.3+k3s1"

  tags = {
    Repo  = "k8s-backup-prototype"
    Owner = data.aws_caller_identity.current.arn
  }
}
