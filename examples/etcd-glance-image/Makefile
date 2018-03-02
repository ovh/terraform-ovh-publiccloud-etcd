OS_REGION_NAME ?= GRA3
PACKERBIN ?= $(shell which packer-io || which packer)
TERRAFORMBIN ?= $(shell which terraform)

all: centos7 coreos

centos7: terraform.tfstate
	$(PACKERBIN) build -var region=$(OS_REGION_NAME) \
								-var source_image_name="Centos 7" \
                -var ssh_username=centos \
	           	  -var ext_net_id=$(shell $(TERRAFORMBIN) output ext_net_id) \
				  packer.json

coreos: terraform.tfstate
	$(PACKERBIN) build -var region=$(OS_REGION_NAME) \
	           	  -var ext_net_id=$(shell $(TERRAFORMBIN) output ext_net_id) \
				  packer.json

.terraform:
	@$(TERRAFORMBIN) init

terraform.tfstate: .terraform
	@$(TERRAFORMBIN) apply -var region=$(OS_REGION_NAME) > /dev/null 2>&1
