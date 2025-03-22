pipeline {
  agent any

  environment {
    DOCKER_IMAGE = "my-microservice:latest"
    KUBE_CONFIG = "--kubeconfig=/home/ec2-user/.kube/config"
  }

  stages {
    stage('Build') {
      steps {
        script {
          sh 'docker build -t ${DOCKER_IMAGE} .'
        }
      }
    }

    stage('SAST') {
      steps {
        script {
          sh 'sonar-scanner -Dsonar.projectKey=my-microservice'
        }
      }
    }

    stage('Container Scan') {
      steps {
        script {
          sh 'trivy image ${DOCKER_IMAGE}'
        }
      }
    }

    stage('Deploy') {
      steps {
        script {
          sh 'kubectl ${KUBE_CONFIG} apply -f k8s/deployment.yaml'
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
