# Run GPU workloads on Amazon ECS or AWS Batch
Amazon ECS와 AWS Batch를 사용하여 `g4dn.xlarge` 인스턴스에서 GPU 지원 작업을 실행하기 위한 Terraform 코드입니다.

### 전제 조건
- AWS 계정
- Terraform [설치](https://developer.hashicorp.com/terraform/install)
- AWS CLI [설치 및 구성](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/getting-started-install.html)

### 설치 방법
1. 이 리포지토리를 클론합니다.
```
git clone https://github.com/didhd/aws-gpu-ecs.git
```
2. Terraform 초기화:
```shell
terraform init
```
3. Terraform 실행:
```shell
terraform apply
```

### 사용 방법
Terraform 명령어가 성공적으로 실행된 후, Output으로 두개의 명령어가 출력됩니다. 
다음 AWS CLI 명령어를 사용하여 ECS 작업을 실행할 수 있습니다. (예시)
```
aws ecs run-task \
    --cluster my-ecs-cluster \
    --task-definition ecs-gpu-task-def \
    --placement-constraints "type=memberOf,expression=attribute:ecs.instance-type == g4dn.xlarge" \
    --network-configuration "awsvpcConfiguration={subnets=["subnet-0ac6407e260cee2fb","subnet-0f3fa0ed09db0ad53","subnet-056e2ddc5f860f3b9"],securityGroups=[\"sg-038c4aae2d01e30a5\"]}" \
    --region us-east-2
```

그리고 AWS Batch 작업도 실행할 수 있습니다. (예시)
```
aws batch submit-job \
    --job-name example-job \
    --job-queue g4dn-queue \
    --job-definition example
    --region us-east-2
```

### Amazon ECS 환경 설정
본 프로젝트의 Terraform 코드는 다음과 같은 Amazon ECS 리소스를 설정합니다:

1. **ECS 클러스터**: 컨테이너화된 애플리케이션을 실행하기 위한 클러스터를 생성합니다.
2. **Task Definition**: GPU를 사용하는 컨테이너 작업을 정의합니다. 이 작업 정의는 g4dn.xlarge 인스턴스에서 실행되도록 구성됩니다.

### AWS Batch 환경 설정

본 프로젝트의 Terraform 코드는 다음 AWS 리소스를 설정합니다:

1. **Compute Environment**: `g4dn.xlarge` 인스턴스를 사용하는 Managed Compute Environment를 생성합니다.
2. **Job Queue**: 작업을 제출할 Job Queue를 생성합니다.
3. **Job Definition**: GPU를 사용하는 컨테이너 작업을 정의합니다.