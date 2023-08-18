output "ssh_command" {
  value = local.ssh_command
}

output "ui" {
  value = <<EOF
user:     admin
password: ${local.ssh_command} cat /var/log/cloud-init-output.log | grep password
host:     http://${aws_instance.server.public_ip}
EOF
}

output "s3_url" {
  value = "s3://${local.bucket_name}@${var.aws_region}/"
}
