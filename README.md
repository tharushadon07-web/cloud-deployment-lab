# Cloud Deployment Lab

A portfolio demonstration of Python, pytest, Docker, Jenkins CI/CD, AWS ECR/ECS Fargate, CloudWatch logs, and Terraform.

## Local (PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-dev.txt
python -m pytest -q
python -m flask --app app.main run --port 5000
```

Visit `http://127.0.0.1:5000` and `/health`.

## Docker

```powershell
docker compose up --build -d
curl.exe http://127.0.0.1:8080/health
docker compose down
```

## Jenkins

Run Jenkins locally from your interactive Windows account (not the default Windows service account), with Python, Docker and AWS CLI in the same PATH. Create a Pipeline job pointing to this Git repo, script path `Jenkinsfile`.

Stages: verify tools, install and test, build image, run smoke test, optionally deploy to AWS. Set `DEPLOY_AWS` to `true` only after provisioning ECS and confirming AWS credentials. Store no secrets in Git.

## AWS (optional, costs money; check billing first)

AWS IAM Identity Center / `aws configure sso` is preferred to long-lived keys. Obtain permission to manage ECR, ECS, CloudWatch, IAM roles, networking, and push images. For a small personal account, use a separate limited lab identity; never use root keys.

1. `cd infra`, `terraform init`, `terraform apply` (service defaults to disabled). This creates the ECR repo plus supporting infrastructure.
2. `cd ..` and `docker build -t cloud-deployment-lab:latest .`
3. Set `$REGION = 'ap-southeast-2'`, `$ACCOUNT = (aws sts get-caller-identity --query Account --output text)`, `$ECR = "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/cloud-deployment-lab"`.
4. `aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"`
5. `docker tag cloud-deployment-lab:latest "${ECR}:latest"` then `docker push "${ECR}:latest"`.
6. `cd infra`, run `terraform apply -var="enable_service=true"` (requires public IPv4/Fargate billing). Wait for task RUNNING.
7. From AWS ECS console, find the task's public IPv4 address; visit `http://PUBLIC_IP:8080/health`. It changes when tasks restart.
8. Configure Jenkins environment variables `DEPLOY_AWS=true`, `AWS_REGION=ap-southeast-2`, and `AWS_ACCOUNT_ID=<account-number>`; AWS CLI credentials must work in the Jenkins user's session. Rebuild the job to push and force a fresh deployment.

**Warning:** This intentionally exposes a demo HTTP service on port 8080 with no user data, authentication or TLS. Never put real customer information here. Production systems should use HTTPS, a proper load balancer, private subnets and stronger network controls. Public IPv4 addresses, ECS Fargate, CloudWatch and ECR can incur charges even if credits are available.

## Clean up to stop charges

From `infra`: `terraform destroy -var="enable_service=true"`. Verify ECS tasks, ECR images, log groups and other resources have been removed from the console. State is local; keep it safe and don't commit it.

## Portfolio evidence

Capture successful pytest output, Jenkins stages, Docker health endpoint, AWS ECS running task, CloudWatch logs, and Terraform plan. Document what failed and how you fixed it. Do not claim components you haven't deployed.
