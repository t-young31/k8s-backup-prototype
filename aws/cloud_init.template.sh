#!/bin/bash

cd /tmp
dnf upgrade -y

# ----------------- k3s setup --------------------------
# cloud-setup needs to be disabled for k3s
# See: https://slack-archive.rancher.com/t/10093428/would-you-expect-k3s-to-install-amp-run-on-an-aws-ec2-rhel9-
systemctl disable nm-cloud-setup.service nm-cloud-setup.timer

# Install k3s
curl https://get.k3s.io | \
  K3S_KUBECONFIG_MODE="644" \
  INSTALL_K3S_EXEC="--cluster-cidr=192.168.0.0/16 --disable=traefik" \
  INSTALL_K3S_VERSION=${k3s_version} sh -

until /usr/local/bin/kubectl get pods -A &> /dev/null; do
  sleep 5
done

# Install open-iscsi, jq, nfs-utils and enable services for Longhorn
dnf install iscsi-initiator-utils jq nfs-utils wget -y
systemctl enable iscsid.service
systemctl start iscsid.service

# Install helm, then the chart
wget https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz -O helm.tar.gz
tar -zxvf helm.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm.tar.gz

helm repo add longhorn https://charts.longhorn.io
helm repo update

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm upgrade --install \
  longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.5.1

# Install nginx ingress
helm upgrade --install \
  ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Create an ingress for accessing the UI
USER=admin
PASSWORD=$(openssl rand -base64 32)
echo "$USER"":$(openssl passwd -stdin -apr1 <<< $PASSWORD)" >> auth
kubectl -n longhorn-system create secret generic basic-auth --from-file=auth

cat <<EOF >> longhorn-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
    nginx.ingress.kubernetes.io/proxy-body-size: 10000m
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
EOF

kubectl -n longhorn-system apply -f longhorn-ingress.yml
