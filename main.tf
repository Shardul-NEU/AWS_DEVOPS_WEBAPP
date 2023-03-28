// network.tf code

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.internet_gateway_name}"
  }
}

//-----------Public Subnet----------------

resource "aws_subnet" "public-subnet" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, var.bits, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.public_subnet_name}-${count.index + 1}"
  }
}

output "subnet_ids" {
  value = aws_subnet.public-subnet.*.id
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

//-----------Private Subnet----------------

resource "aws_subnet" "private-subnet" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, var.bits, (var.subnet_count + 1) + count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.private_subnet_name}-${count.index + 1}"
  }
}

output "private_subnet_ids" {
  value = aws_subnet.private-subnet.*.id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.private_rt_name}"
  }
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

data "aws_availability_zones" "available" {}

# Create security group for web application
resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "HTTPS ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Application ingress"
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
}
output "sec_group_id" {
  value = aws_security_group.app.id
}

// security group for db
resource "aws_security_group" "database" {
    name        = "database"
    description = "Allow access to database"
    vpc_id      = aws_vpc.vpc.id

    ingress {
        description = "MySQL"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.app.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "db_sec_group_id" {
  value = aws_security_group.database.id
}

// IAM role

resource "aws_iam_policy" "policy" {
    name        = "WebAppS3"
    description = "WebAppS3 policy"

    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "s3:GetObject",
                    "s3:DeleteObject",
                    "s3:PutObject",
                    "s3:ListObject"                    
                ],
                "Effect": "Allow",
                "Resource": [
                    "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}",
                    "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}/*"
                ]
            }
        ]
    })
}

resource "aws_iam_role" "iam_role" {
  name = "EC2-CSYE6225"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy_attachment" "policy-attachment" {
  name       = "policy-attachment"
  roles      = [aws_iam_role.iam_role.name]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.iam_role.name
}

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

// instance setup
resource "aws_instance" "my_instance" {
  ami = data.aws_ami.example.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 50
    volume_type = "gp2"
  }
   user_data = <<EOF
    #!/bin/bash
    cd /home/ec2-user/webapp
    echo DBHOST="${aws_db_instance.rds_instance.address}" > .env
    echo DBUSER="${var.username}" >> .env
    echo DBPASS="${var.password}" >> .env
    echo DATABASE="${var.db_name}" >> .env
    echo PORT=${var.app_port} >> .env
    echo DBPORT=${var.db_port} >> .env
    echo BUCKETNAME=${aws_s3_bucket.s3_bucket.id} >> .env

    sudo systemctl daemon-reload
    sudo systemctl start webapp.service
    sudo systemctl enable webapp.service    

  EOF
  subnet_id = aws_subnet.public-subnet.*.id[0]
}

// S3 bucket creation
resource "random_uuid" "uuid" {
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "my-image-bucket-shardul-web"
  force_destroy = true

  tags = {
    Name        = "my-image-bucket-shardul-web"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {

  depends_on = [aws_s3_bucket.s3_bucket]
  bucket     = aws_s3_bucket.s3_bucket.id

  rule {
    id = "log"

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3encrypt" {
  bucket = aws_s3_bucket.s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

output "s3_bucket" {
  value = aws_s3_bucket.s3_bucket.id
}

// database 

resource "aws_db_parameter_group" "parameter_group" {
  name   = "pg-cloud-db"
  family = "mysql8.0"
  description="cloud RDS parameter group"
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet-group"
  subnet_ids = aws_subnet.private-subnet.*.id
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 10
  identifier = "${var.identifier}"
  db_name              = "${var.db_name}"
  engine               = "mysql"
  engine_version       = "${var.engine_version}"
  instance_class       = "db.t3.micro"
  username             = "${var.username}"
  password             = "${var.password}"
  parameter_group_name = "${aws_db_parameter_group.parameter_group.name}"
  skip_final_snapshot  = true
  multi_az=false
  db_subnet_group_name = "${aws_db_subnet_group.subnet_group.name}"
  vpc_security_group_ids = [aws_security_group.database.id]

  //Set it to false.
  publicly_accessible = false
}

output "host_name" {
  value = aws_db_instance.rds_instance.address
}


// Route53 code
data "aws_route53_zone" "selected" {
  name         = var.zonename
  private_zone = false
}
resource "aws_route53_record" "myrecord" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "60"

  depends_on = [aws_instance.my_instance]

  records = [
    aws_instance.my_instance.public_ip,
  ]
}