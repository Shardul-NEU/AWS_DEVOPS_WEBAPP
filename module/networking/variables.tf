variable "cidr_block" {
  type = string
}

variable "instance_tenancy" {
  type = string
}

variable "subnet_count" {
  type = number
}

variable "bits" {
  type = number
}

variable "vpc_name" {
  type = string
}

variable "internet_gateway_name" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "public_rt_name" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "private_rt_name" {
  type = string
  default="myPrivateRT"
}

variable "ec2_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "app_port" {
  description = "Port for the web application"
  type        = number
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}
variable "db_name" {
  type = string
}

variable "db_port" {
  type = number
}

variable "identifier" {
  default = "root"
}

variable "engine_version" {
  default = "8.0"
}
variable "environment" {
  type = string
}

variable "zonename" {
  type = string
}