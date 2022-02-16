default: eu-west-1-up

.PHONY: eu-west-1-up
eu-west-1-up: TARGET_REGION='eu-west-1'
eu-west-1-up: TARGET_SERVERS='eu-west-1-servers'
eu-west-1-up: TARGET_CLIENTS='eu-west-1-clients'
eu-west-1-up: up ## Bring up the eu-west-1 region (default)

.PHONY: eu-west-1-update
eu-west-1-update: TARGET_REGION='eu-west-1'
eu-west-1-update: TARGET_SERVERS='eu-west-1-servers'
eu-west-1-update: TARGET_CLIENTS='eu-west-1-clients'
eu-west-1-update: update ## Update the eu-west-1 region

.PHONY: eu-west-2-up
eu-west-2-up: TARGET_REGION='eu-west-2'
eu-west-2-up: TARGET_SERVERS='eu-west-2-servers'
eu-west-2-up: TARGET_CLIENTS='eu-west-2-clients'
eu-west-2-up: up ## Bring up the eu-west-2 region

.PHONY: eu-west-2-update
eu-west-2-update: TARGET_REGION='eu-west-2'
eu-west-2-update: TARGET_SERVERS='eu-west-2-servers'
eu-west-2-update: TARGET_CLIENTS='eu-west-2-clients'
eu-west-2-update: update ## Update the eu-west-2 region

.PHONY: up
up: vagrant-up machine-install upload-files consul-install nomad-run-dev

.PHONEY: vagrant-up
vagrant-up:
	@vagrant up $(TARGET_REGION)-server-1 $(TARGET_REGION)-client-1 $(TARGET_REGION)-client-2

.PHONY: destroy
destroy: ## Destroy the Vagrant environment with force
	@vagrant destroy -f

.PHONY: machine-install
machine-install:
	@bolt task run machine::prepare --targets=$(TARGET_REGION) --run-as root
	@bolt task run machine::bridge --targets=$(TARGET_CLIENTS) --run-as root
	@bolt task run cni::install --targets=$(TARGET_CLIENTS) --run-as root
	@bolt task run golang::install --targets=$(TARGET_SERVERS) --run-as root
	@bolt task run docker::install --targets=$(TARGET_CLIENTS) --run-as root

.PHONY: consul-install
consul-install:
	@bolt task run consul::prepare --targets=$(TARGET_REGION) --run-as root
	@bolt task run consul::install --targets=$(TARGET_REGION) --run-as root
	@bolt task run service name=consul action=restart --targets=$(TARGET_REGION) --run-as=root

.PHONY: nomad-run-dev
nomad-run-dev:
	@bolt task run nomad::prepare --targets=$(TARGET_REGION) --run-as root
	@bolt task run nomad::build --targets=$(TARGET_SERVERS) --run-as root
	@bolt task run nomad::copy_build --targets=$(TARGET_REGION) --run-as root
	@bolt task run service name=nomad action=restart --targets=$(TARGET_REGION) --run-as=root

.PHONY: update
update: upload-files nomad-run-dev nomad-consul-restart

.PHONY: upload-files
upload-files: upload-client-files upload-server-files

.PHONY: nomad-consul-restart
nomad-consul-restart:
	@bolt task run service name=consul action=restart --targets=$(TARGET_REGION) --run-as=root
	@bolt task run service name=nomad action=restart --targets=$(TARGET_REGION) --run-as=root

.PHONY: upload-client-files
upload-client-files:
	@bolt command run "rm -rf /hashibox/*" --targets=$(TARGET_CLIENTS) --run-as root
	@bolt file upload ./files/$(TARGET_REGION)/client/consul /hashibox --targets=$(TARGET_CLIENTS) --run-as root
	@bolt file upload ./files/$(TARGET_REGION)/client/nomad /hashibox --targets=$(TARGET_CLIENTS) --run-as root

.PHONY: upload-server-files
upload-server-files:
	@bolt command run "rm -rf /hashibox/*" --targets=$(TARGET_SERVERS) --run-as root
	@bolt file upload ./files/$(TARGET_REGION)/server/consul /hashibox --targets=$(TARGET_SERVERS) --run-as root
	@bolt file upload ./files/$(TARGET_REGION)/server/nomad /hashibox --targets=$(TARGET_SERVERS) --run-as root

HELP_FORMAT="    \033[36m%-25s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information
	@echo "HashiBox make commands:"
	@grep -E '^[^ ]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
