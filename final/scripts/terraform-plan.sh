#!/bin/bash

cd ../deployment
terraform fmt
terraform validate
terraform plan -out=planout