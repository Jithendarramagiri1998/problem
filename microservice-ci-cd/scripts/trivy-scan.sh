#!/bin/bash

# Run Trivy container scan
echo "Running Trivy container scan..."
trivy image --config trivy/trivy-config.yaml my-microservice:latest
echo "Trivy container scan completed!"
