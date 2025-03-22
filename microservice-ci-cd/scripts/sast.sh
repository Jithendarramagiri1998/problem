#!/bin/bash

# Run SonarQube SAST
echo "Running SonarQube SAST..."
sonar-scanner \
  -Dsonar.projectKey=my-microservice \
  -Dsonar.sources=./src \
  -Dsonar.host.url=${SONARQUBE_URL} \
  -Dsonar.login=${SONARQUBE_TOKEN}
echo "SonarQube SAST completed!"
