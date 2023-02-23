
data "aws_ami" "example"{
  most_recent = true
  owners = ["892019607445"]

  filter{
    name = "name"
    values = ["my-node-app-ami"]
  }

  filter{
    name = "root-device-type"
    values = ["ebs"]
  }

  filter{
    name = "virtualization-type"
    values = ["hvm"]
  }
}
output ec2_ami{
  value = data.aws_ami.example.id
}

# Create security group for web application
resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
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
    Name = "Web Application Security Group"
  }
}

resource "aws_instance" "my_instance" {
  ami = var.ec2_ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 50
    volume_type = "gp2"
  }
  disable_api_termination = false
}
# code ends here
