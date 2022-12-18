#/bin/bash

# Build the image
docker build -t node_docker_fargate_image ../.

# Get the ecr repo url
url=$(cd ../deployment && terraform output ecr_repo_url | jq -r)


# Tag the image
docker tag node_docker_fargate_image:latest $url:latest

# Push the image to aws ecr
docker push $url:latest