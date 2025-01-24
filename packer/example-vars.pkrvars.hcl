ssh_username               = "ubuntu"
ami_name                   = "dgdo-server"
ami_description            = "AMI for DGDO server"
aws_region                 = "us-west-2"
instance_type              = "t3.micro"
ami_users                  = [] # ["all"] would publish to all
subnet_id                  = ""
vpc_id                     = ""
associate_public_ip_address = false
ssh_interface              = "private_ip"
security_group_id          = ""
run_tags = {
  Name = "dgdo-server"
}
tags = {
  Name = "dgdo-server"
}
