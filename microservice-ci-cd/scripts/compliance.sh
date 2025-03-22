#!/bin/bash

# Enforce compliance with Kyverno
echo "Enforcing compliance with Kyverno..."
kubectl apply -f k8s/kyverno-policy.yaml
echo "Compliance enforcement completed!"