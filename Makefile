SHELL := /bin/bash
.PHONY: *

define terraform-apply
	. init.sh $$ \
    echo "Running: terraform apply on $(1)" && \
    cd $(1) && \
	terraform init -upgrade && \
	terraform validate && \
	terraform apply --auto-approve
endef

define terraform-destroy
	. init.sh $$ \
    echo "Running: terraform destroy on $(1)" && \
    cd $(1) && \
	terraform apply -destroy --auto-approve
endef

all:
	echo "Please make a specific target"; exit 1

aws-login:
	aws configure sso

aws:
	$(call terraform-apply, ./aws)

aws-destroy:
	$(call terraform-destroy, ./aws)

local-k3d:
	./local-k3d/deploy.sh

local-k3d-destroy:
	./local-k3d/destroy.sh
