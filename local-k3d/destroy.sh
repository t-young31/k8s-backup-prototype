#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${script_dir}/../init.sh"

k3d cluster delete "$CLUSTER_NAME"
