pipeline {
    agent any
    options { timestamps(); disableConcurrentBuilds() }
    environment { IMAGE_NAME = 'cloud-deployment-lab' }
    stages {
        stage('Verify Tools') {
            steps { bat 'python --version && docker --version' }
        }
        stage('Install & Test') {
            steps { bat 'python -m pip install -r requirements-dev.txt && python -m pytest -q' }
        }
        stage('Build Docker Image') {
            steps { bat 'docker build -t %IMAGE_NAME%:%BUILD_NUMBER% -t %IMAGE_NAME%:latest .' }
        }
        stage('Container Smoke Test') {
            steps {
                bat 'docker run --rm %IMAGE_NAME%:latest python -c "from app.main import app; assert app.test_client().get(\'/health\').status_code == 200"'
            }
        }
        stage('Push to ECR & Deploy') {
            when { expression { return env.DEPLOY_AWS == 'true' } }
            steps {
                bat '''@echo off
if "%AWS_REGION%"=="" exit /b 1
if "%AWS_ACCOUNT_ID%"=="" exit /b 1
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
if errorlevel 1 exit /b 1
docker tag %IMAGE_NAME%:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%IMAGE_NAME%:latest
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%IMAGE_NAME%:latest
if errorlevel 1 exit /b 1
aws ecs update-service --cluster cloud-lab --service cloud-lab-service --force-new-deployment --region %AWS_REGION%
'''
            }
        }
    }
}
