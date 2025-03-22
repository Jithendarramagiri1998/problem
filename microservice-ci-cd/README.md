# Microservice CI/CD Pipeline

This project demonstrates a CI/CD pipeline with integrated security and compliance for deploying containerized microservices to Kubernetes.

## Features
- **Kubernetes Deployment**: Deploys microservices using Infrastructure as Code (Terraform/Helm).
- **Security Automation**: Integrates SAST (SonarQube), DAST (OWASP ZAP), and container vulnerability scanning (Trivy).
- **Compliance**: Enforces compliance checks using AWS Security Hub and Kyverno.
- **Secret Management**: Uses HashiCorp Vault for secure secret management.
- **Monitoring**: Monitors the application using Prometheus and Grafana.

## Prerequisites
- Jenkins
- Kubernetes cluster
- Docker
- Terraform
- HashiCorp Vault
- Prometheus and Grafana

## Setup
1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/microservice-ci-cd.git
   cd microservice-ci-cd