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
echo "KUBECONFIG=""$KUBECONFIG" | sudo tee -a /etc/environment

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

# Wait for nginx ingress to be up
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Create an ingress for accessing the UI
USER=admin
PASSWORD=$(openssl rand -base64 32)
echo "longhorn password: $PASSWORD"
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
  ingressClassName: nginx
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

# Create the backend for the backups
kubectl create secret generic aws-s3-longhorn \
    --from-literal=AWS_ACCESS_KEY_ID=${longhorn_access_key_id} \
    --from-literal=AWS_SECRET_ACCESS_KEY=${longhorn_access_key_secret} \
    -n longhorn-system


# Install cryptsetup then create a passphrase for kernel-level encrpytion of
# longhorn volumes, then use that to create a custom storage class.
# See: https://longhorn.io/blog/longhorn-v1.2/
dnf install cryptsetup -y

crypt_passphrase=$(openssl rand -base64 32)
echo "crypt passphrase: $crypt_passphrase"

cat <<EOF >> longhorn-crypt-secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto
  namespace: longhorn-system
stringData:
  CRYPTO_KEY_VALUE: "${crypt_passphrase}"
  CRYPTO_KEY_PROVIDER: "secret"
EOF
kubectl -n longhorn-system apply -f longhorn-crypt-secret.yml

cat <<EOF >> longhorn-storage-class.yml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-crypto-global
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "1"
  staleReplicaTimeout: "2880" # 48 hours in minutes
  fromBackup: ""
  encrypted: "true"
  # global secret that contains the encryption key that will be used for all volumes
  csi.storage.k8s.io/provisioner-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/provisioner-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-publish-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-publish-secret-namespace: "longhorn-system"
  csi.storage.k8s.io/node-stage-secret-name: "longhorn-crypto"
  csi.storage.k8s.io/node-stage-secret-namespace: "longhorn-system"
EOF
kubectl -n longhorn-system apply -f longhorn-storage-class.yml


# Disable SElinux for longhorn to function
dnf install grubby -y
grubby --update-kernel ALL --args selinux=0
reboot
