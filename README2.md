In this tutorial we will be completing the following steps:
1. Creating a basic Node.js api application
2. Creating a Docker image to capture the Node.js application
3. Using Terraform to provision an AWS Elastic Container Registry Repository (AWS proprietary container registry - similar to Dockerhub)
4. Building and pushing our Docker image to AWS ECR
5. Using Terraform to provision the following AWS resources: VPC, Subnets, Internet Gateway, Route Table, Security Group, IAM policy, Associated Fargate resources.
6. Writing some bash scripts to help automate the process
___
# Code along

If you want to code along then clone this github repository and work from the `starter` directory.   
I have created all the blank files and we will copy the code over to each file with a short explanation.

```
git clone https://github.com/DarrenK-dev/docker_node_terraform_fargate.git
```

___
# Just clone and run this repository

If you're too busy then you can clone this repository and work from the `final` directory where all the working code will be present.   

You must have aws-cli installed and your default user must have the correct permissions to create the resources contained in the terraform files.

1. Clone this repository
2. Navigate to the `/scripts` directory
3. Enter the following command via your terminal/command line: 
```
./full-run.sh
```
4. When prompted `"Tag and push new image to aws ecr (yes | no)?"` enter `'yes'` to push the docker image to the aws ecr repository that Terraform will create via the script.
5. Once the script has completed you'll have to wait a few minutes for AWS Fargate to provision the associated resources - grab a drink and come back in 5 minutes.
6. While in the `/scripts` directory execute the following script `./get-ip-address.sh` - this will make a few aws-cli calls and finally get the public ip address from our Fargate task and echo it to the console.   
Remember you'll need to prepend the application port `:3003` to the end of the public ipv4 address `ip-address:3003`
7. Enter this address (adding :3003 to the end) and you'll see the application api response in json format.

That's it - we've created a Node.js api, built a Docker image, push that image to AWS ECR, Provisioned Serverless Container Compute with AWS Fargate to serve our Docker image over a public ip address (yes serverless - no Kubernetes of containers to manage, Fargate does the heavy lifting!)


# Create the Node.js application

1. Open your code editor and create a new project directory - I'll create the following directory `~/temp/node_docker_terraform_fargate`.

2. Open 