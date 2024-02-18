variable "aws_region" {
  description = "Declara a região que está sendo utilizada"
  default     = "us-east-1"
  type        = string
}

variable "azs" {
  description = "The availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "The private subnets CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "The public subnets CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instances"
  type        = string
  default     = "deployer_key"

}

variable "instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
  default     = "t2.micro"

}

