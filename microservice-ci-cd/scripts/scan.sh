#!/bin/bash

# Script to run security scans

echo "Running security scans..."

# Run Trivy container scan
echo "Running Trivy container scan..."
trivy image my-microservice:latest

# Run SonarQube SAST
echo "Running SonarQube SAST..."
sonar-scanner \
  -Dsonar.projectKey=my-microservice \
  -Dsonar.sources=./src \
  -Dsonar.host.url=http://<sonarqube-server-ip>:9000 \
  -Dsonar.login=<sonarqube-token>

echo "Security scans complete!"