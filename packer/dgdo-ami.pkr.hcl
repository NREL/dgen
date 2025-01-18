packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t3.micro"
}

source "amazon-ebs" "example" {
  region          = var.aws_region
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      virtualization-type = "hvm"
      architecture = "x86_64"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }
  instance_type   = var.instance_type
  ssh_username    = "ubuntu"
  ami_name        = "dgdo-server"
  ami_description = "dgdo server"
  tags = {
    Name    = "dgdo-server"
  }
}

build {
  sources = ["source.amazon-ebs.example"]

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
