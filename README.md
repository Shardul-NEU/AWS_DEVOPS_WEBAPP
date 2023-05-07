# AWS-infra
This repository contains code for setting up AWS infrastructure resources for hosting a cloud native web application. Terraform is used for infrastructure setup and tear down.

This repository is used in combination with the **WebApp_Shardul** repository containing code of the web application, CI/CD and AMI setup using Packer that is available in the same Github profile. 

# Pre-requisites
Before you can run this Terraform code, you will need to have the following tools installed on your machine:

Terraform
AWS CLI

In addition, you will need to have an AWS account and an IAM user with the necessary permissions.

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

The variables.tf and terraform.tfvars file in this repository defines the input variables that can be used to configure the VPC resources.

To set the values for these variables, you can either modify the default values in the variables.tf file or terraform.tfvars file with your own values.



# Infrastructre provisioned using this terraform code

- **VPC**: The code creates an AWS Virtual Private Cloud (VPC) with a specified `CIDR block`, `instance tenancy`, and `DNS hostname configuration`.

- **Internet Gateway**: An internet gateway is created and associated with the VPC to enable internet access for resources within the VPC.

- **Public Subnet**: Public subnets are created within the VPC. Each subnet has a unique `CIDR block`, `availability zone`, and is associated with the `internet gateway`. These subnets are used for resources that need to be publicly accessible.

- **Public Route Table**: A route table is created and associated with the VPC. It contains a `default route` that directs all traffic (0.0.0.0/0) to the `internet gateway`.

- **Route Table Association**: The public subnets are associated with the `public route table` to enable routing of traffic.

- **Private Subnet**: Private subnets are created within the VPC. Similar to `public subnets`, they have unique `CIDR blocks` and `availability zones`. However, they are not associated with the `internet gateway`, making resources in these subnets private.

- **Private Route Table**: A route table is created for the `private subnets`, but it doesn't contain any routes by default.

- **Security Groups**: Several security groups are defined for different purposes, such as `load balancer security group`, `application security group`, and `database security group`. `Ingress` and `egress` rules are specified to control traffic access.

- **IAM Role**: An IAM role is created with an associated `IAM policy` that allows S3 access. This role is intended for `EC2 instances`.

- **Launch Configuration**: A launch configuration is defined with `user data` that sets up the environment for `EC2 instances`. It includes commands to configure environment variables and start services.

- **Auto Scaling Group**: An auto scaling group is created, which uses the defined `launch configuration` and automatically adjusts the number of EC2 instances based on defined `scaling policies`.

- **CloudWatch Alarms**: CloudWatch `alarms` are created to monitor CPU utilization of the `auto scaling group` instances. Scaling `policies` are associated with these alarms to trigger scaling `actions`.

- **Load Balancer**: An application load balancer (ALB) is created with a `target group` and `listener`. The ALB is associated with the `public subnets` and the `security group`.

- **ACM Certificate**: An ACM certificate is retrieved based on the provided domain name.

- **AWS Load Balancer Listener**: The `aws_lb_listener` resource configures a listener for an Application Load Balancer. It listens on port 443 (HTTPS) and forwards requests to a target group. It also specifies an SSL policy and a certificate for handling HTTPS traffic.

- **AWS S3 Bucket**: Creates an S3 bucket named "my-image-bucket-shardul-web" with the specified tags. The `force_destroy` parameter ensures that the bucket can be destroyed even if it contains objects. `aws_s3_bucket_acl` resource sets the access control list (ACL) for the S3 bucket to "private", ensuring that only the bucket owner has access. `aws_s3_bucket_lifecycle_configuration` resource configures a lifecycle rule for the S3 bucket. In this case, it enables logging and specifies that objects should be transitioned to the STANDARD_IA storage class after 30 days. `aws_s3_bucket_server_side_encryption_configuration` resource configures server-side encryption for the S3 bucket, applying AES256 encryption by default.

- **AWS RDS Database**: `aws_db_parameter_group` resource creates a parameter group for an RDS database specific to the MySQL 8.0 engine. `aws_db_subnet_group` resource creates a subnet group for the RDS database, specifying the subnet IDs where the database can be launched. `aws_db_instance` resource creates an RDS database instance, specifying parameters such as storage, engine, instance class, credentials, security groups, and encryption settings. The `publicly_accessible` parameter is set to false, ensuring that the database is not accessible from the public internet.

- **AWS EC2 Launch Template**: `aws_launch_template` resource defines a launch template for an EC2 instance. It specifies the instance type, image, key pair, network configuration, and tags. Additionally, it includes a block device mapping for an encrypted EBS volume.

- **AWS Route 53 DNS**: `data "aws_route53_zone"` data source retrieves information about a Route 53 hosted zone with the specified name and private_zone parameter. `aws_route53_record` resource creates a Route 53 DNS record, associating the DNS record with the Application Load Balancer's DNS name using an alias.




