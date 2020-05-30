variable "whitelist" {
  type = list(string)
}

provider "aws" {
  access_key = "access_key"
  secret_key = "secret_key"
  region     = "us-west-1"
}

data "aws_elb_service_account" "front_web_lb_account" {}

resource "aws_s3_bucket" "lb_logs" {
  bucket = "distfun-simple-tf-fun-09876"
  acl    = "private"

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::distfun-simple-tf-fun-09876/logs/AWSLogs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.front_web_lb_account.arn}"
        ]
      }
    }
  ]
}
POLICY

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCv8anxkl3kT0T8QpI8/nHafC9ysYG9MA7fdhOSRtF0jT9eaIaamBIxggHFMgRMQJK/OLZlpbMueH4kyBZhDfMAccJInPtZqk8TJwUtSEEHBgsTKj2IdFz3Mda1GdpiJyPojICUVXnbHXZWCO2FLxgn1yvHVbLlVQoVLOthXTtRLQ2QOucxSZGog6ryOAIrhvSG0wvDFjGL+aUirRJPEiklCGjTBaWy7Pb+v8JHxCp/25/4jLUTLJUPsBbzDz4aoN3HC1Q1Ukoj67oe0XZlF2NL8onhex47JJp8vtw2z4dLihCMGFG2ziXAeWk3j4HWclz8/Yn2NWt/KAh3NKqjOth8EdnCgrnEztCHCkXUlefjjlhz7tR/2ZGuSByT8gRBjFv+mMApCXn5w2GrrwrhE49sMzLKvCTtOtaB7EwX6UrBXYXchzBmWtJeaOgvzPsHEWJKt0VX61+kcKZ3DX/zwf0U/CXctZDh2zUY0jKHckexDH/nctK4chNYXecdPOI8fWVk9vuLFQvYlzfUlSdjcext+uteWPGHkvnrfPxYo3LnERCv0f0RgJeOJuyqMKHExfsSqsbn1MkVgC6qi8GS8hfcGE/DTo0HCQzTiL5I7sDo/kTBhUrg4OBfoep62WWqng8KQDGhezxkJABVqqfi6euN7GSoWuAg6WvvtlWmC+yvUw== pawel.dawczak@gmail.com"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-1b"

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-west-1c"

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_security_group" "web" {
  name        = "distfun-simple-tf"
  description = "Allow all the network communication"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 4369
    to_port     = 4369
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 9100
    to_port     = 9155
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.whitelist
  }

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_instance" "web" {
  count = 2

  ami           = "ami-06fcc1f0bc2c8943f"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.my_key.key_name

  availability_zone = "us-west-1b"

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_instance" "web__az_1c" {
  count = 1

  ami           = "ami-06fcc1f0bc2c8943f"
  instance_type = "t2.nano"
  key_name      = aws_key_pair.my_key.key_name

  availability_zone = "us-west-1c"

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

####
#
# Reimplement Loadbalancing to a new Application
# Load balancer in AWS
#
####

resource "aws_lb" "front_web" {
  name               = "front-web"
  internal           = false
  load_balancer_type = "application"

  subnets = [
    aws_default_subnet.default_az1.id,
    aws_default_subnet.default_az2.id,
  ]

  security_groups = [
    aws_security_group.web.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "logs"
    enabled = true
  }

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_lb_listener" "front_web" {
  load_balancer_arn = aws_lb.front_web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_web.arn
  }
}

resource "aws_lb_target_group" "front_web" {
  name_prefix = "front"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_default_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path = "/health"
  }

  tags = {
    "Terraform" : "true",
    "Name" : "DistFunSimple"
  }
}

resource "aws_lb_target_group_attachment" "front_web_i1" {
  target_group_arn = aws_lb_target_group.front_web.arn
  target_id        = aws_instance.web.0.id
}

resource "aws_lb_target_group_attachment" "front_web_i2" {
  target_group_arn = aws_lb_target_group.front_web.arn
  target_id        = aws_instance.web.1.id
}

resource "aws_lb_target_group_attachment" "front_web_i3" {
  target_group_arn = aws_lb_target_group.front_web.arn
  target_id        = aws_instance.web__az_1c.0.id
}

#####
#
# END OF Application Load Balancer
#
#####

#####
#
# OUTPUTS

output "ec2_instances" {
  value = flatten([
    aws_instance.web.*.public_ip,
    aws_instance.web__az_1c[0].public_ip,
  ])
}

output "alb_public_dns" {
  value = aws_lb.front_web.dns_name
}
