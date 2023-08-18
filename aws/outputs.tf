output "ssh_command" {
  value = "ssh -i ${local.ssh_key_name} ${local.ec2_username}@${aws_instance.server.public_ip}"
}
