In this tutorial we will be completing the following steps:
1. Creating a basic Node.js api application
2. Creating a Docker image to capture the Node.js application
3. Using Terraform to provision an AWS Elastic Container Registry Repository (AWS proprietary container registry - similar to Dockerhub)
4. Building and pushing our Docker image to AWS ECR
5. Using Terraform to provision the following AWS resources: VPC, Subnets, Internet Gateway, Route Table, Security Group, IAM policy, Associated Fargate resources.
6. Writing some bash scripts to help automate the process