#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${script_dir}/../init.sh"


function cluster_exists(){
    k3d cluster list | grep -q "$TF_VAR_cluster_name"
}

function create_cluster(){
  k3d cluster create "$TF_VAR_cluster_name" \
    --api-port 6550 \
    --servers 1 \
    --agents 1 \
    --wait

  # --port "${CLUSTER_LOAD_BALANCER_PORT}:80@loadbalancer" \
}

function write_kube_config() {
  k3d kubeconfig get "$TF_VAR_cluster_name" > "$1"
  chmod 600 "$1"
}

if ! cluster_exists; then
  create_cluster
  write_kube_config "${script_dir}/../kube_config.yaml"
else
  echo "Cluster [${TF_VAR_cluster_name}] exists"
fi
