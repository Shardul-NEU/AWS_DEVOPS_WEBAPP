module "my_network_0" {
  source = "./module/networking"

  vpc_cidr_block             = "10.0.0.0/16"
  vpc_name                   = "my-vpc"
  public_subnet_cidr_blocks  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidr_blocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones         = ["us-east-1a", "us-east-1b", "us-east-1c"]
  igw_name                   = "my-igw"
}
