# simple-node-app-with-terraform-on-aws

1.  Create our base terraform files and configuration
2.  Create a ECR repository to store our Docker image
3.  Authenticate Docker to AWS so we can push changes to ECR
4.  Create a basic Node api application using express
5.  Create a Dockerfile so we can create a Docker images of our application
6.  Push our image to ECR

## AWS iAM User

You'll require an aws user linked to terraform - I will be using the `default` profile for all commands in this tutorial.

## 1. Create our base terraform files and confi`guration

In this tutorials I will be working in a directory located at `~/temp/node_docker_fargate`.

### providers.tf

I'm going to store all of our terraform code in a separate directory called `deployment`, so let's create that now:
```
mkdir -p ~/temp/node_docker_fargate/deployment
```

Create a file called `providers.tf` in the `~/temp/node_docker_fargate/deployment` directory with the following code:

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
  alias   = "our_user"
}
```

Now open a terminal window, navigate to our project directory:
```
cd ~/temp/node_docker_fargate/deployment
```

Enter the following command:
```
terraform init
```

If you've entered the correct configuration as above then you'll receive a message in your command prompt similar to this: `Terraform has been successfully initialized!`

## 2. Create a ECR repository to store our Docker image

In this step we'll use terraform to create a new ECR on AWS. The purpose of this repository is to store our Docker image code in a place that can be easily accessible by AWS Fargate so when we come to deploy the application we can easily do so.

Create a new file called `ecr.tf` in the deployment directory of or project with the following code.

```
resource "aws_ecr_repository" "ecr" {
  provider     = aws.our_user
  name         = "simple-node-app-with-terraform-on-aws"
  force_delete = true
}

output "ecr_repo_url" {
  value = aws_ecr_repository.ecr.repository_url
}
```
We're using the configuration we've defined in our provider code block with the alias `our_user` by using the `provider = aws.our_user` line - so this ECR will be created in the `us-east-1` region.

Now run the following commands in the terminal you have open:

```
terraform fmt
```
...the `fmt` command simply formats our `.tf` files so they look pretty and consistent.

```
terraform validate
```
...the `validate` command tries to validate our code syntax - it's not perfect but it can catch any syntax errors like missing curly braces, I find it good practice to run both of theses commands.

```
terraform plan -out=planout
```
...the `plan` command compares the terraform state against your project code - if there are any differences then it will tell you what resources terraform will provisioned /changed / destroy if we apply the changes. I've added the optional `-out` flag and set the file as `planout` - this can be any name you want but I find it quite descriptive.

```
terraform apply planout
```
...this is where we tell terraform to apply the changes detailed in the passed file, in our case the `planout` file. 
___
### Optional step - bash script to run 4 terraform commands
It can be a little tedious running all four commands every time you want to apply any changes (especially in development or while learning). With that in mind I usually create a bash script to run all four commands, here is how to setup the script:

In your open terminal (make sure you're in the `/deployment` directory) enter the following commands:
```
touch apply.sh &&
chmod 770 apply.sh
```
...here we're creating the bash script file and changing it's permissions so we can execute it using the `./<SCRIPT-FILE-HERE>` syntax.

Open the file with your text editor and enter the following code:
```
#!/bin/bash

terraform fmt
terraform validate
terraform plan -out=planout
terraform apply planout
```

When we're inside the `/deployment` directory from terminal we can enter the command:
```
./apply.sh
```
and all four commands will execute - if a stage fails then the planout file will become 'stale' and the `terraform apply` command won't execute / provision.

So run the `./apply.sh` script (or the four terraform commands detailed above) and lets see if our ECR repository will be created.

If the deployment is successful then you'll receive a message similar to `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

We can use the asw-cli to check with the following command:
```
aws ecr describe-repositories --profile default
```
REMEMBER - we have to provide the aws-cli user name after the `--profile` flag not the alias.
```
~/temp/node_docker_fargate/deployment/providers.tf

provider "aws" {
  profile = "default" # <--- This one!
  region  = "us-east-1"
  alias   = "our_user" # <--- NOT this one!
}
```

this command will return a list / array of our ECR repositories - it should contain a ECR with a similar output to this:
```
{
    "repositories": [
        {
            "repositoryArn": "arn:aws:ecr:us-east-1:041*******26:repository/simple-node-app-with-terraform-on-aws",
            "registryId": "041*******26",
            "repositoryName": "simple-node-app-with-terraform-on-aws",
            "repositoryUri": "041*******26.dkr.ecr.us-east-1.amazonaws.com/simple-node-app-with-terraform-on-aws",
            "createdAt": "2022-12-12T10:57:50+00:00",
            "imageTagMutability": "MUTABLE",
            "imageScanningConfiguration": {
                "scanOnPush": false
            },
            "encryptionConfiguration": {
                "encryptionType": "AES256"
            }
        }
    ]
}
```

Alternatively you can login to the AWS console, search for Elastic Container Registry (or 'ECR'), click on 'Repositories' and you should see the repository named `simple-node-app-with-terraform-on-aws`.

Great! we've now got our repository setup using terraform, we need to add a container image to this repo, but before that we need to authenticate our aws ecr account with docker.
___
## Authenticate Docker to AWS so we can push changes to ECR

In-order for Docker to communicate with our AWS ECR account we need to authenticate.   
There are a few variables we need for this process:
- Our AWS account id
- Our Profile region

I'm going to use a command line tool called `jq` to parse json objects output in the command line, you can use python or other tools but `jq` is simple and light weight.

Let's get our aws account id and store it to an environment variable called $AWS_ACCOUNT_ID.   

Open your terminal and enter the following command:
```
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile default --output json | jq -r ".Account")
```
...this command gets the identity of the profile we provide, it will return a json object with a number of properties, we are only interested in the property named "Account" so we pipe the json object to `jq` and parse out the "Account" property, we then store that to the environment variable `$AWS_ACCOUNT_ID`.

Now we need our profile region, lets save it to an env variable called $REGION
```
REGION=$(aws configure get region --profile default)
```
...much the same as above we're hitting the aws api and requesting the region associated with the profile we provide - in this case we're using the default profile. We're storing this into the env variable `$REGION`

Now that we have the two pieces of information required to authenticate we can enter the following command:
```
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
```

Here aws cli is requesting a authorization-token from aws ecr in the specified region. We then pipe that token to a docker login command - AWS is handling the connection, we simply have to provide the `--password-stdin` portion with the url aws specifies in their documentation - we only have to change out the account_id and region portion for our own credentials and AWS will take-care of the rest. REMEMBER - we could pass the region as a string and the account id as a string BUT I did want to showcase the power of the aws cli and environment variables as we can use these to streamline and automate the process.

As we're talking about DevOps if we can automate the process then we will! Take a look at the script below.
___
### Optional Script - automate the authentification process.

Lets first create the bash script file in the `/deployment` directory and change its permissions.

```
touch auth-docker.sh &&
chmod 770 auth-docker.sh
```
Enter the following code to the file:
```
#!/bin/bash

# Ask user to input the --profile name
read -p "Enter aws profile: " profile

# Make the call to get the $profile account id
aws_account_id=$(aws sts get-caller-identity --profile $profile --output json | jq -r ".Account")

# Get the region of the entered $profile
region=$(aws configure get region --profile $profile)

# Finally authenticate Docker with AWS account for $profile and $region
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin "$aws_account_id.dkr.ecr.$region.amazonaws.com"
```

Use the above script by running the command:
```
./auth-docker.sh
```
...enter the name of your aws-cli --profile (we're using `default` in this tutorial, so enter "default") and the script should take care of the rest. If successful then you'll receive the output `Login Succeeded`. I find this a good practice as we've condensed three some-what complicated commands down to a single command that accepts an aws-cli user as it's only input - this will be less prone to errors and streamlines the process of authenticating aws ecr with docker.

Now we've provision our ecr repository and authenticated aws ecr to docker we can move onto coding our simple Node api app.

___

## Create a basic Node api application using express

We going to create a backend api that returns a json response to any client that sends a request to a defined endpoint. It's basic but will be good enough for our tutorial.

Open a terminal and navigate to the project **root** directory.
```
cd ~/temp/node_docker_fargate
```

You'll need Node installed if you want to run the following command on your local machine. Don't worry if you don't because you can skip this part and just copy copy the files from here to your local machine without running any of the following commands.

I'm using `Node v18.4.0` in this tutorial. 

```
node --version
```

If you have Node installed on your local machine then you can enter the following command:
```
npm init -y
```
This command will setup the scaffolding for our Node app including the `package.json` file, it should look something like this:
```
{
  "name": "simple-node-app-with-terraform-on-aws",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

We're going to install `express` to help create our app, enter the command:
```
npm install --save-exact express@4.18.2
```

The `package.json` file should have changed to now include:
```
...
"dependencies": {
    "express": "4.18.2"
}
...
```
I've pinned the version to `4.18.2` so your code will work exactly the same as my code and to avoid any future breaking changes.

Here's my final package.json file, if you don't have Node installed on your local machine then just copy the code across to your project root directory (you wont have to enter the `npm init` or `npm install` commands.):
```
{
  "name": "simple-node-app-with-terraform-on-aws",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "darrenk.dev",
  "license": "ISC",
  "dependencies": {
    "express": "4.18.2"
  }
}
```

Time to create the application api code.

Create a file called `index.js` in the root directory of our project.

Enter the following code:
```
const express = require('express');
const PORT = process.env.PORT | 3003;

const app = express();

app.get('/', (req, res) => {
  res.status(200);
  res.json({
    website: "darrenk.dev",
    tutorial: "simple-node-app-with-terraform-on-aws",
    tags: ["aws", "node", "docker", "terraform", "fargate"]
  });
  res.end()
})

app.listen(PORT, () => {
  console.log(`Node server is listening on port ${PORT}`)
})
```

If you have Node installed on your local machine then you can run the following command:
```
node index.js
```
Open a web browser and goto the url `http://localhost:3003/`   
There you'll see the json response from our api endpoint.
( *to stop the app just press Ctrl + c* )

That's of basic Node api created - lets move onto Docker!
___

## Create a Dockerfile

Now we've got our Node app created we need to create a Dockerfile that we'll use to create a Docker image. A Docker image is like a blueprint on how Docker will create the container.

Create a new file in the root of our project directory called `Dockerfile`.

Copy the following code into the file:
```
# FROM node:18
FROM node:18.4.0-bullseye-slim
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm i
COPY . .
EXPOSE 3003
CMD [ "node", "app.js" ]
```

As you can see I've commented out `FROM node:18`   
I've done this because `node:18` is a large base image approaching 1GB in size - we don't need the full version for this tutorial so I've chosen a smaller version `FROM node:18.4.0-bullseye-slim` - this will speed up our image build time considerably.

Now we've got the Dockerfile setup we need to build a docker image from it, open terminal, navigate to the root directory of our project (this is where our Dockerfile is saved) and enter the following command:
```
docker build -t node_docker_fargate .
```

Docker will look for a `Dockerfile` in the local directory because we've ended the command with `.` - it will take the information from the Dockerfile and build a Docker image named `node_docker_fargate`.

Now we need to tag the image with our erc repository url.   
Lucky for us we included a `output` block in the `ecr.tf` file that stores the ecr repo url we need!

to retrieve the url enter the following command:
```
terraform output ecr_repo_url
```

Copy the url from the command line and replace the `<repo_url>` section with the copied url and enter the command.

```
docker tag node_docker_fargate:latest <repo_url>:latest
```

It should look something like this:
```
docker tag node_docker_fargate:latest 041*******26.dkr.ecr.us-east-1.amazonaws.com/simple-node-app-with-terraform-on-aws:latest
```

Now we just have to push our image to our aws ecr repository with the following command:
```
docker push <repo_url>:latest
```

But I'm sure you're expecting me to provide a script to automate the process a little...? So take a look at the script I've written below before you push the image to you ecr repository:
___
### Optional Script

Lets "bash" out a short script to automate this process (*sorry for the poor joke* 😊).

Create a file in the `/deployment` directory called `docker-tag.sh` and change the permissions:
```
touch docker-tag-and-push.sh &&
chmod 770 docker-tag-and-push.sh
```
Now open the file and copy the following code across:
```
#!/bin/bash

1.# Build the image
docker build -t node_docker_fargate ../.

2.# Get the ecr repo url
url=$(terraform output ecr_repo_url | jq -r)

3.# Tag the image
docker tag node_docker_fargate:latest $url:latest

4.# Push the image to aws ecr
docker push $url:latest
```

So what's happening here?   
1.  We're building the docker image with a hardcoded tag `node_docker_fargate` using the Dockerfile in the directory above (*yes we could ask the user to input a tag dynamically - but you've got to do some of the work yourself*).
2.  We're getting the repo_url stored in a terraform output and stripping out the double quotes using `jq -r` flag.
3.  Then we tag the image with our aws ecr repo name (getting it ready to push)
4.  Finally push the repo up to our aws ecr repository

Now we have an aws ecr repository called `simple-node-app-with-terraform-on-aws` that has an image tag `latest` containing our Node api application.
___

## AWS Elastic Container Service (ECS)

We now need to write the code to deploy the image as a container to aws, we're going to use terraform to provision this using a principle called infrastructure as code - IaC.

The first thing required is the correct permissions for deploying our image with ECS, so lets create a new IAM role called `ecs_role`.

### iam.tf

Create a new file in the `/deployment` directory called `iam.tf` and enter the following code:
```
resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"

  assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "ecs_policy_attachment" {
  role = aws_iam_role.ecs_role.name

  // This policy adds logging + ecr permissions
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
 ```

The first resource block creates the policy role - you can see any resource that assumes this role will be allowed the `"Service": "ecs-tasks.amazonaws.com"` permissions - in short be able to perform ecs tasks.

The second resource block is attaching a preexisting policy called `AmazonECSTaskExecutionRolePolicy` to our newly created role, this will add the following permissions to our new role:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

As you can see from the `ecr:...` properties it will allow our role to interact with aws ecr (where our docker image is stored) and pull the image down from the repository.

### network.tf
It's always a good idea to provision or use a pre-configured VPC when deploying your resources to aws (normally **not** the default VPC and subnets). So lets create some networking infrastructure.

Create a new file in the `/deployment` directory called `network.tf` and enter the following code:

```
data "aws_availability_zones" "available" {
  provider = aws.default
  state = "available"
}

resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "node_docker_tutorial"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.custom_vpc.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.custom_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_security_group" "custom_security_group" {
  name        = "custom_security_group"
  description = "Allow TLS inbound traffic on port 80 (http)"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 3003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "custom_security_group"
  }
}
```

There's lots going on in this file if you'tr not familiar with aws and terraform but I'll briefly explain what's going on.

The first `data` block is pulling in the available availability_zones in our region - the region is being pulled from our `providers.tf` file and our default provider code block.

The `resource "aws_vpc" "custom_vpc" {...}` block is provisioning a new vpc with the cidr_block 10.0.0.0/16.

We're then creating two subnets within that vpc, and placing them in different availability zones - you can see were using the `data` block and selecting different availability zones using `[0]` and `[1]`.

Our containers need access to the internet so we need an internet gateway attached to our vpc.

We also need to configure a route table and a security group to direct traffic securely. You can see we've opened up port 3003 for incoming traffic because that's the port we're using for our Node app.

## AWS Fargate

I'll be using Fargate to deploy the containers in this tutorial as I don't want to over complicate the tutorial more than necessary as Fargate will help abstract away some of the complications with managing containers. I'm sure I'll post more content with EKS in the future.

Create a new file called `fargate.tf` inside the `/deployment` directory and add the following code:
```
resource "aws_ecs_task_definition" "backend_task" {
  family = "backend_example_app_family"

  // Fargate is a type of ECS that requires awsvpc network_mode
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  // Valid sizes are shown here: https://aws.amazon.com/fargate/pricing/
  memory = "512"
  cpu    = "256"

  // Fargate requires task definitions to have an execution role ARN to support ECR images
  execution_role_arn = aws_iam_role.ecs_role.arn

  container_definitions = <<EOT
[
    {
        "name": "example_app_container",
        "image": "<your_ecr_repo_url>:latest",
        "memory": 512,
        "essential": true,
        "portMappings": [
            {
                "containerPort": 3003,
                "hostPort": 3003
            }
        ]
    }
]
EOT
}

resource "aws_ecs_cluster" "backend_cluster" {
  name = "backend_cluster_example_app"
}

resource "aws_ecs_service" "backend_service" {
  name = "backend_service"

  cluster         = aws_ecs_cluster.backend_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn

  launch_type   = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets          = ["${aws_subnet.public_a.id}", "${aws_subnet.public_b.id}"]
    security_groups  = ["${aws_security_group.custom_security_group.id}"]
    assign_public_ip = true
  }
}
```