# aws-infra
This repository contains code for setting up AWS networking resources such as Virtual Private Cloud (VPC), Internet Gateway, Route Table, and Routes. Terraform is used for infrastructure setup and tear down.

# Terraform AWS VPC Example
This repository contains Terraform code to provision an AWS Virtual Private Cloud (VPC), along with subnets, routing tables, and an Internet Gateway.

# Pre-requisites
Before you can run this Terraform code, you will need to have the following tools installed on your machine:

Terraform
AWS CLI

In addition, you will need to have an AWS account and an IAM user with the necessary permissions to provision VPC resources.

To configure your AWS CLI, you can run the following command:
-> aws configure

This will prompt you for your AWS Access Key and Secret Key, as well as your default region and output format.

# Usage
To use this Terraform code, follow these steps:

1) Clone this repository to your local machine.
2) In the root directory of the repository, run terraform init to initialize Terraform and download any necessary plugins.
3) Run terraform plan to see the proposed changes that will be made to your AWS account. Review the output and ensure that the changes are what you expect.
4) If everything looks good, run terraform apply to apply the changes and provision your VPC resources.
5) To destroy the resources when you're finished, run terraform destroy.

# Configuration

The variables.tf file in this repository defines the input variables that can be used to configure the VPC resources.

To set the values for these variables, you can either modify the default values in the variables.tf file or create a terraform.tfvars file with your own values.

For example, to set the vpc_cidr_block variable to a custom value, you could create a terraform.tfvars file with the following content:
-> vpc_cidr_block = "10.0.0.0/16"




