data "aws_ami" "example" {
  most_recent = true
  owners      = ["892019607445"]

  filter {
    name   = "name"
    values = ["my-node-app-ami"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "my_network_0" {
  source = "./module/networking"

  cidr_block            = var.vpc_cidr_block
  instance_tenancy      = var.vpc_instance_tenancy
  subnet_count          = var.subnet_count
  bits                  = var.subnet_bits
  vpc_name              = var.vpc_name
  internet_gateway_name = var.vpc_internet_gateway_name
  public_subnet_name    = var.vpc_public_subnet_name
  public_rt_name        = var.vpc_public_rt_name
  private_subnet_name   = var.vpc_private_subnet_name
  private_rt_name       = var.vpc_private_rt_name
  ec2_ami               = data.aws_ami.example.id
  app_port              = 3000
  db_port = 3306
  username = "root"
  password = "pass1234"
  db_name = "webapp"
  environment = "dev"
  zonename="dev.shardul-deshmukh.me"
}
