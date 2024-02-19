# aws-gpu-ecs
Amazon ECS 또는 AWS Batch를 사용하여 GPU 지원 작업을 실행하기 위한 Terraform 코드입니다. `g4dn.xlarge` 인스턴스를 예시로 사용하였습니다.

### 전제 조건
- AWS 계정
- Terraform 설치
- AWS CLI 설치 및 구성

### 설치 방법
1. 이 리포지토리를 클론합니다.
```
git clone <repository-url>
```
2. Terraform 초기화:
```shell
terraform init
```
3. Terraform 실행:
```shell
terraform apply
```

## 사용 방법
Terraform이 생성되면, Output으로 두개의 명령어가 출력됩니다. 
다음 AWS CLI 명령어를 사용하여 ECS 작업을 실행할 수 있습니다. (예시)
```
aws ecs run-task \
    --cluster my-ecs-cluster \
    --task-definition ecs-gpu-task-def \
    --placement-constraints "type=memberOf,expression=attribute:ecs.instance-type == g4dn.xlarge" \
    --network-configuration "awsvpcConfiguration={subnets=["subnet-0ac6407e260cee2fb","subnet-0f3fa0ed09db0ad53","subnet-056e2ddc5f860f3b9"],securityGroups=[\"sg-038c4aae2d01e30a5\"]}" \
    --region us-east-2
```

그리고 AWS Batch 작업도 실행할 수 있습니다. (예시))
```
aws batch submit-job \
    --job-name example-job \
    --job-queue g4dn-queue \
    --job-definition example
    --region us-east-2
```