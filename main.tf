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

# security group for load balancer

resource "aws_security_group" "load_balancer_sg" {
  name_prefix = "load_balancer_security_group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for web application
resource "aws_security_group" "app" {
  name_prefix = "app-"
  vpc_id = aws_vpc.vpc.id
  # ingress {
  #   description = "HTTPS ingress"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "HTTP ingress"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # security_groups = [aws_security_group.load_balancer_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Application ingress"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
    # cidr_blocks = ["0.0.0.0/0"]
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
                    "s3:*"                    
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

resource "aws_iam_policy_attachment" "policy-attachment-cloudwatch" {
  name       = "policy-attachment-cloudwatch"
  roles      = [aws_iam_role.iam_role.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.iam_role.name
}

data "aws_ami" "example" {
  most_recent = true
  owners      = ["892019607445"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Define the launch configuration

data "template_file" "userData" {
  template = <<EOF
    #!/bin/bash
    cd /home/ec2-user/WebApp/webapp
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

    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/cloudwatch-config.json \
    -s  

    EOF
}

resource "aws_kms_key" "ebs_encryption_key" {
  description              = "EBS encryption key"
  deletion_window_in_days  = 10
  # customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User permissions"
        Effect = "Allow"
        Principal = {AWS = "*"}
        Action = "kms:*"
        Resource = "*"
      }
    ]
  })
}

locals {
  aws_account_id = "273198842666"
}

resource "aws_kms_key" "rds_encryption_key" {
  description              = "RDS encryption key"
  deletion_window_in_days  = 10
  # customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "Enable IAM User permissions"
        Effect = "Allow"
        Principal = {AWS = "*"}
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid = "Allow usage of the key for RDS"
        Effect = "Allow"
        Principal = { AWS = ["arn:aws:iam::${local.aws_account_id}:root"]}
        Action = [
          "kms:Encrpyt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:generateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

// AWS autoscaling group defined

resource "aws_autoscaling_group" "my_autoscaling_group" {
  name = "my_autoscaling_group"
  default_cooldown    = 60
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }
  vpc_zone_identifier = aws_subnet.public-subnet[*].id
  health_check_type = "EC2"
  tag {
    key                 = "webapp"
    value               = "webappInstance"
    propagate_at_launch = true
  }
  target_group_arns = [aws_lb_target_group.web.arn]  
  health_check_grace_period = 300
  # termination_policies = ["OldestInstance"]
}

// auto scaling up-down policy

resource "aws_cloudwatch_metric_alarm" "scaleUpAlarm" {
  alarm_name          = "ASG_Scale_Up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }

  alarm_description = "Scale up if CPU > 5% for 1 minute"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scaleDownAlarm" {
  alarm_name          = "ASG_Scale_Down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }

  alarm_description = "Scale down if CPU < 3% for 2 minutes"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name = "scale_up_policy"
  policy_type = "SimpleScaling"
  scaling_adjustment = 1
  adjustment_type  = "ChangeInCapacity" 
  cooldown = 60 # cooldown in seconds
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
  metric_aggregation_type = "Average"
  # alarm_name = aws_cloudwatch_metric_alarm.cpu_utilization_alarm.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name = "scale_down_policy"
  policy_type = "SimpleScaling"
  scaling_adjustment = -1 
  adjustment_type = "ChangeInCapacity"
  cooldown = 60 # cooldown in seconds
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
  metric_aggregation_type = "Average"
  # alarm_name = aws_cloudwatch_metric_alarm.cpu_utilization_alarm.name
}


// Load Balancer Defined
resource "aws_lb" "web" {
  name = "web-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.load_balancer_sg.id]
  # subnets = var.subnet_ids
  subnets = aws_subnet.public-subnet[*].id
}

resource "aws_lb_target_group" "web" {
  name = "web-tg"
  port = 3000
  protocol = "HTTP"
  
  #cross-check below line
  vpc_id = aws_vpc.vpc.id
}

data "aws_acm_certificate" "issued" {
  domain   = "${var.zonename}"
  statuses = ["ISSUED"]
}


resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:acm:us-east-1:273198842666:certificate/10891b2b-e7e9-4c1a-b117-78d982537bc3"
  certificate_arn = data.aws_acm_certificate.issued.arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# resource "aws_lb_target_group_attachment" "webapp_tg_at" {
#   target_group_arn = aws_lb_target_group.webapp_tg.arn
#   target_id        = aws_autoscaling_group.asg.name
#   port             = 3000
# }

// instance setup
# resource "aws_instance" "my_instance" {
#   ami = data.aws_ami.example.id
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.app.id]
#   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
#   ebs_block_device {
#     device_name = "/dev/xvda"
#     volume_size = 50
#     volume_type = "gp2"
#   }
#    user_data = <<EOF
#     #!/bin/bash
#     cd /home/ec2-user/WebApp/webapp
#     echo DBHOST="${aws_db_instance.rds_instance.address}" > .env
#     echo DBUSER="${var.username}" >> .env
#     echo DBPASS="${var.password}" >> .env
#     echo DATABASE="${var.db_name}" >> .env
#     echo PORT=${var.app_port} >> .env
#     echo DBPORT=${var.db_port} >> .env
#     echo BUCKETNAME=${aws_s3_bucket.s3_bucket.id} >> .env

#     sudo systemctl daemon-reload
#     sudo systemctl start webapp.service
#     sudo systemctl enable webapp.service

#     sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#     -a fetch-config \
#     -m ec2 \
#     -c file:/opt/cloudwatch-config.json \
#     -s  

#   EOF
#   subnet_id = aws_subnet.public-subnet.*.id[0]
# }

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
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_encryption_key.arn

  //Set it to false.
  publicly_accessible = false
}

output "host_name" {
  value = aws_db_instance.rds_instance.address
}

resource "aws_launch_template" "app_server" {
  name = "app_server"
  image_id  = data.aws_ami.example.id
  instance_type = "t2.micro"
  key_name = "CLI_Access"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }
  tags = {
    Name = "EC2-${data.aws_ami.example.id}"
  }

##########ASSG 8
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
    
      volume_size = 8
      volume_type = "gp2"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs_encryption_key.arn
    }
  }
  
  user_data = base64encode(data.template_file.userData.rendered) 
}


// Route53 code
data "aws_route53_zone" "selected" {
  name         = var.zonename
  private_zone = false
}

resource "aws_route53_record" "webapp_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${data.aws_route53_zone.selected.name}"
  type    = "A"
  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}
