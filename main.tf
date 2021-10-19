resource "aws_vpc" "main" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "TEK-UP"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  ingress = [
    {
      description      = "from Public SG to Private SG"
      from_port        = 22
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.allow_http.id]
      self             = false
    }
  ]

  egress = [
    {
      description      = "main VPC"
      prefix_list_ids  = []
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow Pub SG"
  }
  revoke_rules_on_delete = true

}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      description      = "internet to Pub subnet"
      from_port        = 22
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress = [
    {
      description = "HTTP from VPC"

      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow_internet_access"
  }
  revoke_rules_on_delete = true


}

resource "aws_route_table" "custom-rt" {
  vpc_id = aws_vpc.main.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      gateway_id                 = aws_internet_gateway.igw.id
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }
  ]

  tags = {
    Name = "Custom RT"
  }
  depends_on = [
    aws_internet_gateway.igw
  ]

}

resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.main.id

  route = [

    {
      cidr_block                 = "0.0.0.0/0"
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      gateway_id                 = ""
      nat_gateway_id             = aws_nat_gateway.nat-gateway.id
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }


  ]

  tags = {
    Name = "Main RT"
  }
  depends_on = [
    aws_nat_gateway.nat-gateway
  ]
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.custom-rt.id
}
resource "aws_route_table_association" "pb1" {
  subnet_id      = aws_subnet.pb-subnet-1.id
  route_table_id = aws_route_table.custom-rt.id
}
resource "aws_route_table_association" "pb2" {
  subnet_id      = aws_subnet.pb-subnet-2.id
  route_table_id = aws_route_table.custom-rt.id
}
resource "aws_route_table_association" "prv1" {
  subnet_id      = aws_subnet.prv-subnet-1.id
  route_table_id = aws_route_table.main-rt.id
}
resource "aws_route_table_association" "prv2" {
  subnet_id      = aws_subnet.prv-subnet-2.id
  route_table_id = aws_route_table.main-rt.id
}
resource "aws_subnet" "pb-subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public-subnet-ip[0]

  tags = {
    Name = "Public Subnet 01"
  }
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  depends_on = [
    aws_vpc.main
  ]
}


resource "aws_subnet" "pb-subnet-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public-subnet-ip[1]

  tags = {
    Name = "Public Subnet 02"
  }
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_subnet" "prv-subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private-subnet-ip[0]

  tags = {
    Name = "Private Subnet 01"
  }
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_subnet" "prv-subnet-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private-subnet-ip[1]

  tags = {
    Name = "Private Subnet 02"
  }
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false
  depends_on = [
    aws_vpc.main
  ]
}
resource "aws_eip" "elp" {
  vpc = true
  depends_on = [
    aws_internet_gateway.igw
  ]

}
resource "aws_nat_gateway" "nat-gateway" {
  subnet_id         = aws_subnet.pb-subnet-1.id
  connectivity_type = "public"
  allocation_id     = aws_eip.elp.id
  depends_on = [
    aws_internet_gateway.igw,
    aws_eip.elp
  ]

}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


resource "aws_launch_configuration" "be-as-conf" {
  name_prefix   = "backend-conf"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.ec2-instance-type
  root_block_device {
    encrypted = true
  }
  key_name = var.public-key-name

  user_data_base64 = "IyEgL2Jpbi9iYXNoCiAgICB5dW0gdXBkYXRlIC15CgkJeXVtIC15IGluc3RhbGwgaHR0cGQKCQlzeXN0ZW1jdGwgc3RhcnQgaHR0cGQKCQlzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCgkJZWNobyAnPGh0bWw+PGgxPkhlbGxvIGZyb20gQVdTICE8L2gxPjwvaHRtbD4nID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1s"

  lifecycle {
    create_before_destroy = false
  }

}

resource "aws_autoscaling_group" "asg" {

  name                      = "backend-asg"
  launch_configuration      = aws_launch_configuration.be-as-conf.name
  min_size                  = var.asg-min
  max_size                  = var.asg-max
  health_check_grace_period = 30
  health_check_type         = "ELB"
  desired_capacity          = var.asg-des
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.prv-subnet-1.id, aws_subnet.prv-subnet-2.id]
  #availability_zones        = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "CreatedByASG"
    propagate_at_launch = true
  }
}
# Create a new load balancer



resource "aws_lb" "be-elb" {

  name               = "be-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.pb-subnet-1.id, aws_subnet.pb-subnet-2.id]

  enable_deletion_protection = false




  tags = {
    Name = "backend-terraform-elb"
  }
}


resource "aws_autoscaling_attachment" "asg_attachment_elb" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = aws_lb_target_group.lbtg.arn
}
resource "aws_lb_target_group" "lbtg" {
  name     = "lbtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.be-elb.arn
  port              = "80"
  protocol          = "HTTP"
  ssl_policy        = ""
  certificate_arn   = ""

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg.arn
  }
}





resource "aws_instance" "jumpbox" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ec2-instance-type
  subnet_id                   = aws_subnet.pb-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.allow_http.id]
  availability_zone           = data.aws_availability_zones.available.names[0]
  associate_public_ip_address = true

  metadata_options {

    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  ebs_optimized = false
  root_block_device {
    encrypted = true
  }
  user_data_base64 = "IyEgL2Jpbi9iYXNoCiAgICB5dW0gdXBkYXRlIC15CgkJeXVtIC15IGluc3RhbGwgaHR0cGQKCQlzeXN0ZW1jdGwgc3RhcnQgaHR0cGQKCQlzeXN0ZW1jdGwgZW5hYmxlIGh0dHBkCgkJZWNobyAnPGh0bWw+PGgxPkhlbGxvIGZyb20gQVdTICE8L2gxPjwvaHRtbD4nID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1s"
  tags = {
    Name = "Jumb box"
  }
  key_name = var.public-key-name
  depends_on = [
    aws_security_group.allow_http
  ]

}
data "aws_instances" "nodes" {
  depends_on = [aws_autoscaling_group.asg]

  instance_tags = {
    Name = "CreatedByASG"
  }

}
data "aws_instance" "asg-instances" {
  count       = var.asg-min
  depends_on  = [data.aws_instances.nodes]
  instance_id = data.aws_instances.nodes.ids[count.index]
}
