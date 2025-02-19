.PHONY: aws-init aws-plan aws-apply aws-deploy aws-destroy run-task-ecs

# Inicializar Terraform
aws-init:
	terraform init

# Ejecutar plan con inicialización previa
aws-plan: aws-init
	terraform plan

# Ejecutar apply con inicialización previa
aws-apply: aws-init
	terraform apply -auto-approve

# Ejecutar plan y apply (despliegue completo)
aws-deploy: aws-plan
	terraform apply -auto-approve

# Destruir la infraestructura
aws-destroy:
	terraform destroy -auto-approve

# Ejecutar una tarea ECS usando el comando de salida de Terraform
run-task-ecs:
	$(shell terraform output -raw run_ecs_task_command)
