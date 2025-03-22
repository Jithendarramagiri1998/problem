#!/bin/bash

# Set up Prometheus and Grafana
echo "Setting up Prometheus and Grafana..."
kubectl apply -f prometheus/prometheus.yml
kubectl apply -f grafana/dashboard.json
echo "Prometheus and Grafana setup completed!"
