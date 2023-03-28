 variable "cidr_block" {
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
}

variable "app_port" {
  description = "Port that the application is running on"
  type = number
}

variable "db_port" {
  description = "Port that the database runs on"
  type = number
}

variable "identifier" {
  type = string
  default = "root"
}

variable "engine_version" {
  default = "8.0"
}

variable "username" {
  description = "username of the database"
  type = string
  default = "root"
}

variable "password" {
  description = "password of the database"
  type = string
}

variable "db_name" {
  description = "name of the database"
  type = string
  default = "webapp"
}

variable "zonename" {
  description = "hosted zone name"
  type = string
}

variable "environment" {
  description = "env of aws"
  type = string
} 

variable "region" {
  type = string
  default = "us-east-1"
}