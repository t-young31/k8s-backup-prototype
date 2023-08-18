resource "null_resource" "create_cluster" {
  provisioner "local-exec" {
    command = "${path.module}/create_cluster.sh"
  }
}

resource "null_resource" "destroy_cluster" {
  triggers = {
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = "k3d cluster delete ${self.triggers.cluster_name}"
    when    = destroy
  }
}
