#!/bin/bash

terraform fmt
terraform validate
terraform plan -out=planout
terraform apply planout