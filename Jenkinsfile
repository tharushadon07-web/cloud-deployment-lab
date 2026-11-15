
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    parameters {
        booleanParam(
            name: 'DEPLOY_AWS',
            defaultValue: false,
            description: 'Push to AWS ECR and deploy to ECS'
        )

        string(
            name: 'AWS_REGION',
            defaultValue: 'ap-southeast-2',
            description: 'AWS region'
        )
    }

    environment {
        IMAGE_NAME = 'cloud-deployment-lab'
    }

    stages {

        stage('Verify Tools') {
            steps {
                bat '''
                    @echo off

                    python --version
                    if errorlevel 1 exit /b 1

                    docker --version
                    if errorlevel 1 exit /b 1

                    aws --version
                    if errorlevel 1 exit /b 1

                    echo All required tools available.
                '''
            }
        }

        stage('Verify AWS Authentication') {
            when {
                expression { return params.DEPLOY_AWS }
            }

            steps {
                withEnv([
                    'AWS_PROFILE=cloud-lab-deploy',
                    'AWS_DEFAULT_REGION=ap-southeast-2'
                ]) {
                    bat '''
                        @echo off

                        aws sts get-caller-identity --query Arn --output text
                        if errorlevel 1 exit /b 1

                        aws ecr describe-repositories --repository-names cloud-deployment-lab --region ap-southeast-2 --query "repositories[0].repositoryName" --output text
                        if errorlevel 1 exit /b 1

                        echo AWS deployment identity verified.
                    '''
                }
            }
        }

        stage('Install & Test') {
            steps {
                bat '''
                    @echo off

                    python -m pip install -r requirements-dev.txt
                    if errorlevel 1 exit /b 1

                    python -m pytest -q
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    @echo off

                    docker build -t %IMAGE_NAME%:%BUILD_NUMBER% -t %IMAGE_NAME%:latest .
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Container Smoke Test') {
            steps {
                bat '''@echo off
docker run --rm %IMAGE_NAME%:latest python -c "from app.main import app; assert app.test_client().get('/health').status_code == 200"
if errorlevel 1 exit /b 1
'''
            }
        }

        stage('Push to ECR & Deploy') {
            when {
                expression { return params.DEPLOY_AWS }
            }

            steps {
                withEnv([
                    'AWS_PROFILE=cloud-lab-deploy',
                    'AWS_DEFAULT_REGION=ap-southeast-2'
                ]) {
                    bat '''
                        @echo off
                        powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "scripts\\deploy-aws.ps1"
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'BUILD SUCCESSFUL.'
        }

        failure {
            echo 'BUILD FAILED. Check console output.'
        }

        always {
            echo 'Pipeline finished.'
        }
    }
}
