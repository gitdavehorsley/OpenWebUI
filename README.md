# OpenWebUI - AWS Fargate Deployment

A CloudFormation template for deploying [OpenWebUI](https://github.com/open-webui/open-webui) on Amazon ECS Fargate within a private VPC. This template provides a secure, scalable web interface for AI models with integration to AWS Bedrock.

## 🚀 Features

- **Private VPC Deployment**: Secure deployment within your existing VPC
- **VPC Endpoints**: Truly private deployment with no internet access required
- **ECS Fargate**: Serverless container orchestration with automatic scaling
- **Application Load Balancer**: Internal load balancer for high availability
- **AWS Bedrock Integration**: Built-in permissions for AWS Bedrock model access
- **Secrets Manager Integration**: Secure API key management
- **ARM64 Architecture**: Optimized for cost and performance
- **Security Groups**: Proper network isolation and access control

## 📋 Prerequisites

Before deploying this template, ensure you have:

1. **AWS CLI** configured with appropriate permissions
2. **Existing VPC** with private subnets (minimum 2 for high availability)
3. **ECR Repository** containing the OpenWebUI Docker image
4. **Secrets Manager Secret** (optional) for storing API keys
5. **AWS Bedrock** access (if using Bedrock models)

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client/Bastion│    │  Application     │    │   ECS Fargate   │
│   (VPN/Direct   │───▶│  Load Balancer   │───▶│   Tasks         │
│   Connect)      │    │  (Internal)      │    │   (Private)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   VPC Endpoints  │
                       │   (ECR, Secrets, │
                       │   Bedrock, etc.) │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   AWS Services   │
                       │   (Private)      │
                       └──────────────────┘
```

## 📦 Deployment

### Step 1: Deploy VPC Endpoints (Required for Private Deployment)

**IMPORTANT**: For a truly private deployment with no internet access, you must deploy the VPC endpoints first. This ensures your OpenWebUI containers can access AWS services without requiring internet connectivity.

```bash
aws cloudformation create-stack \
    --stack-name OpenWebUI-VPCEndpoints \
    --template-body file://VpcEndpoints.template \
    --parameters \
        ParameterKey=VpcId,ParameterValue=vpc-XXXXXXXXX \
        ParameterKey=PrivateSubnetIds,ParameterValue="subnet-XXXXXXXXX,subnet-YYYYYYYYY" \
        ParameterKey=CreatedBy,ParameterValue="YourName"
```

This creates VPC endpoints for:
- **ECR API & DKR**: For pulling Docker images
- **Secrets Manager**: For accessing API keys
- **EFS**: For file system operations
- **Bedrock**: For AI model inference
- **CloudWatch Logs & Monitoring**: For logging and metrics

### Step 2: Prepare Your Environment

Ensure you have the OpenWebUI Docker image in your ECR repository:

```bash
# Build and push the OpenWebUI image to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build the image
docker build -t openwebui .

# Tag and push to ECR
docker tag openwebui:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/openwebui:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/openwebui:latest
```

### Step 3: Create Secrets Manager Secret (Optional)

If you need to store API keys securely:

```bash
aws secretsmanager create-secret \
    --name "openwebui/api-key" \
    --description "API Key for OpenWebUI" \
    --secret-string '{"api_key":"your-api-key-here"}'
```

### Step 4: Deploy the OpenWebUI CloudFormation Stack

```bash
aws cloudformation create-stack \
    --stack-name OpenWebUI-Fargate \
    --template-body file://OpenWebUIFargate.template \
    --parameters \
        ParameterKey=EcrRepositoryUri,ParameterValue=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/openwebui:latest \
        ParameterKey=EcrRepositoryArn,ParameterValue=arn:aws:ecr:us-east-1:YOUR_ACCOUNT_ID:repository/openwebui \
        ParameterKey=ApiKeySecretArn,ParameterValue=arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:openwebui/api-key-XXXXX \
        ParameterKey=VpcId,ParameterValue=vpc-XXXXXXXXX \
        ParameterKey=PrivateSubnetIds,ParameterValue="subnet-XXXXXXXXX,subnet-YYYYYYYYY" \
        ParameterKey=AllowedCidrBlocks,ParameterValue="10.0.0.0/8,172.16.0.0/12" \
        ParameterKey=CreatedBy,ParameterValue="YourName"
```

### Step 5: Monitor Deployment

```bash
# Check VPC Endpoints deployment
aws cloudformation describe-stacks --stack-name OpenWebUI-VPCEndpoints --query 'Stacks[0].StackStatus'

# Check OpenWebUI deployment
aws cloudformation describe-stacks --stack-name OpenWebUI-Fargate --query 'Stacks[0].StackStatus'
```

## 🔒 Private Deployment Benefits

By deploying the VPC endpoints first, you achieve:

- **No Internet Access Required**: All AWS service communication stays within your VPC
- **Enhanced Security**: Eliminates potential attack vectors from internet
- **Better Performance**: Lower latency for AWS service calls
- **Compliance**: Meets strict security requirements for private environments
- **Cost Optimization**: No NAT Gateway charges for AWS service access

## ⚙️ Configuration Parameters

### VPC Endpoints Template Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| `VpcId` | Existing VPC ID | Yes |
| `PrivateSubnetIds` | List of private subnet IDs (minimum 2) | Yes |
| `CreatedBy` | Creator identifier | Yes |

### OpenWebUI Template Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `EcrRepositoryUri` | ECR repository URI for OpenWebUI image | - | Yes |
| `EcrRepositoryArn` | ARN of the ECR repository | - | Yes |
| `ApiKeySecretArn` | Secret ARN for API key storage | - | No |
| `VpcId` | Existing VPC ID | - | Yes |
| `PrivateSubnetIds` | List of private subnet IDs | - | Yes |
| `AllowedCidrBlocks` | CIDR blocks allowed to access UI | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` | No |
| `WebPort` | Port for web UI access | `80` | No |
| `DesiredCount` | Number of ECS tasks | `1` | No |
| `Cpu` | CPU units for tasks | `1024` | No |
| `Memory` | Memory for tasks (MiB) | `2048` | No |
| `CreatedBy` | Creator identifier | - | Yes |

## 🔧 Environment Variables

The template configures the following environment variables for OpenWebUI:

- `OLLAMA_BASE_URL`: Set to `http://localhost:11434` (for Ollama integration)
- `WEBUI_SECRET_KEY`: Secret key for web UI security
- `DEFAULT_MODELS`: Default model selection (`claude-3-5-sonnet`)
- `ENABLE_SIGNUP`: Disabled for security (`false`)
- `ENABLE_LOGIN_FORM`: Enabled (`true`)
- `OPENAI_API_KEY`: Retrieved from Secrets Manager

## 🔐 Security Features

- **Private VPC**: All resources deployed in private subnets
- **Security Groups**: Restrictive network access rules
- **IAM Roles**: Least privilege access for ECS tasks
- **Secrets Manager**: Secure API key storage
- **Internal Load Balancer**: No direct internet access

## 📊 Resource Requirements

### Minimum Configuration
- **CPU**: 1024 (1 vCPU)
- **Memory**: 2048 MiB
- **Tasks**: 1

### Recommended Configuration
- **CPU**: 2048 (2 vCPU)
- **Memory**: 4096 MiB
- **Tasks**: 2 (for high availability)

## 🌐 Accessing the Application

After deployment, the OpenWebUI will be accessible via the internal load balancer DNS name. You can access it through:

1. **VPN Connection** to your VPC
2. **AWS Systems Manager Session Manager** through a bastion host
3. **Direct Connect** or **VPC Peering**

The URL will be in the CloudFormation outputs as `WebUIUrl`.

## 🔄 Scaling

The template supports horizontal scaling by adjusting the `DesiredCount` parameter. For automatic scaling based on metrics, you can add CloudWatch alarms and ECS service scaling policies.

## 🧹 Cleanup

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name OpenWebUI-Fargate
```

## 📝 Notes

- The deployment uses ARM64 architecture for cost optimization
- All resources are tagged with the `CreatedBy` parameter for tracking
- The load balancer is internal-only for security
- ECS tasks run in private subnets with no public IP assignment

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 References

- [OpenWebUI GitHub Repository](https://github.com/open-webui/open-webui)
- [AWS ECS Fargate Documentation](https://docs.aws.amazon.com/ecs/latest/userguide/what-is-fargate.html)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/) 