#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${script_dir}/../init.sh"


function cluster_exists(){
    k3d cluster list | grep -q "$CLUSTER_NAME"
}

function create_cluster(){
  k3d cluster create "$CLUSTER_NAME" \
    --api-port 6550 \
    --servers 1 \
    --agents 1 \
    --wait

  # --port "${CLUSTER_LOAD_BALANCER_PORT}:80@loadbalancer" \
}

function write_kube_config() {
  k3d kubeconfig get "$CLUSTER_NAME" > "${script_dir}/../${CLUSTER_CONFIG_FILE}"
  chmod 600 "$CLUSTER_CONFIG_FILE"
}

if ! cluster_exists; then
  create_cluster
  write_kube_config
else
  echo "Cluster [${CLUSTER_NAME}] exists"
fi
