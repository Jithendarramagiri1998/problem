#!/bin/bash

# Run SonarQube SAST
echo "Running SonarQube SAST..."
sonar-scanner \
  -Dsonar.projectKey=my-microservice \
  -Dsonar.sources=./src \
  -Dsonar.host.url=http://<sonarqube-server-ip>:9000 \
  -Dsonar.login=<sonarqube-token>
echo "SonarQube SAST completed!"