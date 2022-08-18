default: help

.PHONY: multi-region-server-build
multi-region-server-build: ## Build a multi-region cluster with servers only
	@vagrant up eu-west-2-server-1 eu-central-1-server-1
	@cd multi-region-server-only && terraform init && terraform apply --auto-approve

.PHONY: multi-region-server-destroy
multi-region-server-destroy: ## Destroy a multi-region cluster with servers only
	@vagrant destroy -f eu-west-2-server-1 eu-central-1-server-1
	@cd multi-region-server-only && rm -rf terraform.tfstate .terraform

.PHONY: single-region-build
single-region-build: ## Build a single-region cluster
	@vagrant up eu-west-2-server-1 eu-west-2-client-1 eu-west-2-client-2
	@cd single-region && terraform init && terraform apply --auto-approve

.PHONY: single-region-destroy
single-region-destroy: ## Destroy a single-region cluster
	@vagrant destroy -f eu-west-2-server-1 eu-west-2-client-1 eu-west-2-client-2
	@cd single-region && rm -rf terraform.tfstate .terraform

HELP_FORMAT="    \033[36m%-29s\033[0m %s\n"
.PHONY: help
help: ## Display this usage information
	@echo "make commands:"
	@grep -E '^[^ ]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
			{printf $(HELP_FORMAT), $$1, $$2}'
