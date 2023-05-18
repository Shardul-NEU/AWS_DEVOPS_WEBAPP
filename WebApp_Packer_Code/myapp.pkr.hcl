variable "aws_access_key" {default = ""}
variable "aws_secret_key" {default = ""}
variable "aws_region" {default = "us-east-1"}
variable "vpc_id" {default = "vpc-0fee9139a03822322"}
variable "subnet_id" {default = "subnet-03f1a8b1975d560e8"}
variable "instance_type" {default = "t2.micro"}
variable "ami_name" {default = "my-node-app-ami"}
variable "ami_users" {default = ["418151176571"]}

source "amazon-ebs" "amazon-linux-2" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region

  instance_type = var.instance_type
  ssh_username  = "ec2-user"

  ami_name = "my-node-app-ami_${formatdate("YYYY_MM_DD_hh_mm_ss", timestamp())}"

  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id

  associate_public_ip_address = true
  ami_users = var.ami_users

  tags = {
    Name = var.ami_name
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    delete_on_termination = true
    volume_size           = 8
    volume_type           = "gp2"
  }

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
}

build {
  name        = "my-node-app-ami_${formatdate("YYYY_MM_DD_hh_mm_ss", timestamp())}"
  description = "My custom AMI"
  sources     = [
    "source.amazon-ebs.amazon-linux-2"
  ]

  provisioner "file" {
    source      = "dist/WebApp.zip"
    destination = "/home/ec2-user/WebApp.zip"
  }

   provisioner "shell" {
   
    script = "./provision.sh"
    # environment_vars = ["DATABASEUSER=${var.DATABASEUSER}", "DATABASEPASSWORD=${var.DATABASEPASSWORD}", "DATABASEHOST=${var.DATABASEHOST}", "PORT=${var.PORT}", "DATABASE=${var.DATABASE}", "DBPORT=${var.DBPORT}"]
  }
  
   // Replace with actual AWS account IDs
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}