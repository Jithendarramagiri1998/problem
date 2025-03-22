#!/bin/bash

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
echo "Deployment to Kubernetes completed!"