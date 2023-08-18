locals {
  ec2_username = "ec2-user"
  ssh_key_name = "ec2_id_rsa"

  k3s_version = "v1.27.3+k3s1"

  bucket_name = aws_s3_bucket.backup.bucket
  ssh_command = "ssh -i ${local.ssh_key_name} ${local.ec2_username}@${aws_instance.server.public_ip}"

  tags = {
    Repo  = "k8s-backup-prototype"
    Owner = data.aws_caller_identity.current.arn
  }
}
