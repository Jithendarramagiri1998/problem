#!/bin/bash

# Build Docker image
echo "Building Docker image..."
docker build -t my-microservice:latest ./src
echo "Docker image built successfully!"