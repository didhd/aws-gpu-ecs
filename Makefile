.PHONY: aws-init aws-plan aws-apply aws-deploy aws-destroy run-task-ecs

aws-init:
	@echo "Terraform initializing..."
	terraform init

aws-plan: aws-init
	@echo "Terraform plan..."
	terraform plan

aws-apply: aws-init
	@echo "Terraform apply..."
	terraform apply -auto-approve

aws-deploy: aws-plan aws-apply

aws-lint: aws-init
	@echo "Terraform lint..."
	@cd $(TF_DIR) && terraform fmt && terraform validate

aws-destroy: aws-init
	@echo "¡CAUTION! This is going to destroy all AWS infraestructure related with Horizons. Are you really sure? (y/N)"
	@read -p "Answer: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Launch teraform destroy..."; \
		terraform destroy -auto-approve; \
	else \
		echo "Operation cancelled"; \
	fi

run-task-ecs:
	$(shell terraform output -raw run_ecs_task_command)
