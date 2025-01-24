packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "ssh_username" {
  default = "ubuntu"
}

variable "ami_name" {
  default = "dgdo-server"
}

variable "ami_description" {
  default = "AMI for DGDO server"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_users" {
  default = ""
}

variable "subnet_id" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "associate_public_ip_address" {
  default = false
}

variable "ssh_interface" {
  default = "private_ip"
}

variable "security_group_id" {
  default = ""
}

variable "run_tags" {
  type = map(string)
  default = {
    Name       = "dgdo-server"
  }
}

variable "tags" {
  type = map(string)
  default = {
    Name       = var.ami_name
  }
}

source "amazon-ebs" "dgdo_ami" {
  region                    = var.aws_region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type             = var.instance_type
  ssh_username              = var.ssh_username
  ami_name                  = var.ami_name
  ami_description           = var.ami_description
  tags                      = var.tags
  run_tags                  = var.run_tags
  subnet_id                 = var.subnet_id
  vpc_id                    = var.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
  security_group_id         = var.security_group_id
  ami_users                 = var.ami_users
  ssh_interface             = var.ssh_interface
}

build {
  sources = ["source.amazon-ebs.dgdo_ami"]

  provisioner "file" {
    source      = "../../dgen"
    destination = "/home/ubuntu/dgen"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}
