pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "my-microservice:latest"
        KUBE_CONFIG = "--kubeconfig=/home/ec2-user/.kube/config"
        VAULT_ADDR = "http://<vault-server-ip>:8200"
        VAULT_TOKEN = "<vault-token>"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-repo/microservice.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }

        stage('SAST with SonarQube') {
            steps {
                script {
                    sh 'sonar-scanner -Dsonar.projectKey=my-microservice -Dsonar.sources=. -Dsonar.host.url=http://<sonarqube-server-ip>:9000 -Dsonar.login=<sonarqube-token>'
                }
            }
        }

        stage('Container Scan with Trivy') {
            steps {
                script {
                    sh 'trivy image ${DOCKER_IMAGE}'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl ${KUBE_CONFIG} apply -f k8s/deployment.yaml'
                }
            }
        }

        stage('DAST with OWASP ZAP') {
            steps {
                script {
                    sh 'zap-baseline.py -t http://<microservice-url>'
                }
            }
        }

        stage('Compliance Check with AWS Security Hub') {
            steps {
                script {
                    sh 'aws securityhub get-findings'
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
