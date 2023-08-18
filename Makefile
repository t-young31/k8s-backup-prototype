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
	$(call terraform-apply, .)

destroy:
	$(call terraform-destroy, .)

aws-login:
	aws configure sso

aws:
	$(call terraform-apply, ./aws)

aws-destroy:
	$(call terraform-destroy, ./aws)

local-k3d:
	$(call terraform-apply, ./local-k3d)

local-k3d-destroy:
	$(call terraform-apply, ./local-k3d)
