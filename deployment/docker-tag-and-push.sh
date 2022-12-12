#!/bin/bash

# Build the image
docker build -t node_docker_fargate ../.

# Get the ecr repo url
url=$(terraform output ecr_repo_url | jq -r)

# Tag the image
docker tag node_docker_fargate:latest $url:latest

# Push the image to aws ecr
docker push $url:latest