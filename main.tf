provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "aula-03-eriktonon"
    key    = "aula-03/terraform.tfstate"
    region = "us-east-1"

  }
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.5.2"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs                = var.azs
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "sg" {
  source      = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.1"
  depends_on  = [module.vpc]
  name        = "my-security-group"
  description = "meu primeiro security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "open http port"
      cidr_blocks = "0.0.0.0/0" 
    },

  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

data "aws_ami" "ubuntu_server" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source                 = "git::https://github.com/terraform-aws-modules/terraform-aws-ec2-instance.git?ref=v5.6.0"
  depends_on             = [module.sg]
  ami                    = data.aws_ami.ubuntu_server.id
  instance_type          = var.instance_type
  count                  = 2
  key_name               = var.key_name
  monitoring             = true
  associate_public_ip_address = true
  vpc_security_group_ids = [module.sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 10
    }
  ]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "aula-03"
    Name        = "aula-03-instance-${count.index}"
  }
}


module "alb" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-alb.git?ref=v6.0.0"
  name    = "my-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.sg.security_group_id]

  http_tcp_listeners = [{
    port               = 80
    protocol           = "HTTP"
    target_group_index = 0
  }]

  target_groups = [{
    name_prefix      = "tg"
    backend_protocol = "HTTP"
    backend_port     = 80
    target_type      = "instance"
  }]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "aula-03"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count = length(module.ec2_instance)

  target_group_arn = module.alb.target_group_arns[0]
  target_id        = module.ec2_instance[count.index].id
  port             = 80
}
