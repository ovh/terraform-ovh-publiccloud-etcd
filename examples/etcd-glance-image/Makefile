OS_REGION_NAME ?= GRA3
PACKERBIN ?= $(shell which packer-io || which packer)
CFSSL_MOD_VERSION ?= 0.1.1

all: centos7 coreos

.terraform:
	@terraform init

terraform.tfstate: .terraform
	@terraform apply -var region=$(OS_REGION_NAME) > /dev/null 2>&1

install-cfssl-$(CFSSL_MOD_VERSION)/terraform-ovh-publiccloud-cfssl-$(CFSSL_MOD_VERSION)/modules/install-cfssl:
	@mkdir install-cfssl-$(CFSSL_MOD_VERSION)
	@curl -L --fail --silent -o install-cfssl-$(CFSSL_MOD_VERSION)/mod.tar.gz https://github.com/ovh/terraform-ovh-publiccloud-cfssl/archive/v$(CFSSL_MOD_VERSION).tar.gz
	@tar -xzf install-cfssl-$(CFSSL_MOD_VERSION)/mod.tar.gz -C install-cfssl-$(CFSSL_MOD_VERSION)

centos7: terraform.tfstate install-cfssl-$(CFSSL_MOD_VERSION)/terraform-ovh-publiccloud-cfssl-$(CFSSL_MOD_VERSION)/modules/install-cfssl
	$(PACKERBIN) build -var region=$(OS_REGION_NAME) \
								-var source_image_name="Centos 7" \
                -var ssh_username=centos \
								-var cfssl_install_dir=./install-cfssl-$(CFSSL_MOD_VERSION)/terraform-ovh-publiccloud-cfssl-$(CFSSL_MOD_VERSION)/modules/install-cfssl \
	           	  -var ext_net_id=$(shell terraform output | awk -F 'ext_net_id = ' '/ext_net_id/ {print $$2}') \
				  packer.json

coreos: terraform.tfstate install-cfssl-$(CFSSL_MOD_VERSION)/terraform-ovh-publiccloud-cfssl-$(CFSSL_MOD_VERSION)/modules/install-cfssl
	$(PACKERBIN) build -var region=$(OS_REGION_NAME) \
	           	  -var ext_net_id=$(shell terraform output | awk -F 'ext_net_id = ' '/ext_net_id/ {print $$2}') \
								-var cfssl_install_dir=./install-cfssl-$(CFSSL_MOD_VERSION)/terraform-ovh-publiccloud-cfssl-$(CFSSL_MOD_VERSION)/modules/install-cfssl \
				  packer.json
