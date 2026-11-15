
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(false)
    }

    parameters {
        booleanParam(
            name: 'DEPLOY_AWS',
            defaultValue: false,
            description: 'Deploy application to AWS ECS'
        )

        string(
            name: 'AWS_REGION',
            defaultValue: 'ap-southeast-2',
            description: 'AWS deployment region'
        )

        string(
            name: 'AWS_ACCOUNT_ID',
            defaultValue: '',
            description: 'AWS account ID'
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

                    echo All required tools are available.
                '''
            }
        }

        stage('Verify AWS Authentication') {
            steps {
                withEnv([
                    'AWS_PROFILE=cloud-lab',
                    'AWS_DEFAULT_REGION=ap-southeast-2'
                ]) {
                    bat '''
                        @echo off

                        echo Checking AWS authentication...

                        aws sts get-caller-identity --query Arn --output text
                        if errorlevel 1 exit /b 1

                        echo Checking ECR repository access...

                        aws ecr describe-repositories --repository-names cloud-deployment-lab --region ap-southeast-2 --query "repositories[0].repositoryName" --output text
                        if errorlevel 1 exit /b 1

                        echo AWS authentication and ECR access verified.
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
                expression {
                    return params.DEPLOY_AWS
                }
            }

            steps {
                error(
                    'AWS deployment is not configured yet. ' +
                    'Restricted AWS credentials and ECR authentication ' +
                    'must be configured before enabling deployment.'
                )
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }

        always {
            echo 'Build finished.'
        }
    }
}
