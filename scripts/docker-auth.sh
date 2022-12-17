#!/bin/bash

# Ask user to input the --profile name
# read -p "Enter aws profile: " profile
profile=default

# Make the call to get the $profile account id
aws_account_id=$(aws sts get-caller-identity --profile $profile --output json | jq -r ".Account")

# Get the region of the entered $profile
region=$(aws configure get region --profile $profile)

# Finally authenticate Docker with AWS account for $profile and $region
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$aws_account_id.dkr.ecr.$region.amazonaws.com"