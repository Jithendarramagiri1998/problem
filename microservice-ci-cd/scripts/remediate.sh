#!/bin/bash

# Script to automate remediation tasks

echo "Running remediation tasks..."

# Check for critical vulnerabilities in the Docker image
echo "Checking for critical vulnerabilities..."
trivy_output=$(trivy image my-microservice:latest --severity CRITICAL)

if echo "$trivy_output" | grep -q "CRITICAL"; then
  echo "Critical vulnerabilities detected. Rolling back deployment..."
  kubectl rollout undo deployment/my-microservice
else
  echo "No critical vulnerabilities detected."
fi

echo "Remediation tasks complete!"