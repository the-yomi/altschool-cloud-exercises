terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Provisioning virtual private cloud and more
provider "aws" {
  region = "us-east-1" 
}

resource "aws_vpc" "tvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "tvpc"
  }
}


resource "aws_internet_gateway" "t_internetgateway" {
  vpc_id= aws_vpc.tvpc.id
  tags = {
    Name = "t_internetgateway"
  }
}

resource "aws_route_table" "t_publicroutetable" {
  vpc_id = aws_vpc.tvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.t_internetgateway.id 
  }
  tags = {
    Name = "t_publicroutetable"
  }
}

# CREATING SUBNETS


resource "aws_subnet" "t_publicsubnet1" {
  vpc_id = aws_vpc.tvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "t_publicsubnet1"
  }
}

resource "aws_subnet" "t_publicsubnet2" {
  vpc_id = aws_vpc.tvpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = {
    Name = "t_publicsubnet2"
  }
}

resource "aws_subnet" "t_publicsubnet3" {
  vpc_id = aws_vpc.tvpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1c"
  tags = {
    Name = "t_publicsubnet3"
  }
}


#ASSOCIATING PUBLIC SUBNETS WITH PUBLIC ROUTE TABLE 

resource "aws_route_table_association" "t_publicsubnet1association" {
  subnet_id = aws_subnet.t_publicsubnet1.id
  route_table_id = aws_route_table.t_publicroutetable.id
}

resource "aws_route_table_association" "t_publicsubnet2association" {
  subnet_id = aws_subnet.t_publicsubnet2.id
  route_table_id = aws_route_table.t_publicroutetable.id
}

resource "aws_route_table_association" "t_publicsubnet3association" {
  subnet_id = aws_subnet.t_publicsubnet3.id
  route_table_id = aws_route_table.t_publicroutetable.id
}

# CREATING NACL 

resource "aws_network_acl" "t_NACL" {
  vpc_id = aws_vpc.tvpc.id
  subnet_ids = [aws_subnet.t_publicsubnet1.id, aws_subnet.t_publicsubnet2.id, aws_subnet.t_publicsubnet3.id]
  ingress{
    rule_no = 100
    protocol = "-1"
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  egress {
    rule_no = 100
    protocol = "-1"
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}



# SECURITY GROUPS FOR LOADBALANCER

resource "aws_security_group" "t_loadbalancersg" {
  name = "t_loadbalancersg"
  vpc_id = aws_vpc.tvpc.id

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
    from_port = 80
    to_port = 80
    protocol ="tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SECURITY GROUP FOR INSTANCES

resource "aws_security_group" "t_instancesg" {
  name = "t_instancesg"
  vpc_id = aws_vpc.tvpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.t_loadbalancersg.id]

  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.t_loadbalancersg.id]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol ="-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { 
    Name = "t_instancesg"
  }
}

# SPINNING UP INSTANCES
resource "aws_instance" "t_webserver1" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "nginx"
  security_groups = [aws_security_group.t_instancesg.id]
  subnet_id = aws_subnet.t_publicsubnet1.id
  availability_zone = "us-east-1a"
  provisioner "local-exec" {
    command = "echo '${self.public_ip}' >> /vagrant/Terraform_MiniProject/host-inventory"
  
  }

  tags = { 
    Name = "t_webserver1"
    source = "terraform"
  }
}

resource "aws_instance" "t_webserver2" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "nginx"
  security_groups = [aws_security_group.t_instancesg.id]
  subnet_id = aws_subnet.t_publicsubnet2.id
  availability_zone = "us-east-1b"

provisioner "local-exec" {
    command = "echo '${self.public_ip}' >> /vagrant/Terraform_MiniProject/host-inventory"
}

  tags = { 
    Name = "t_webserver2"
    source = "terraform"
  }
}

resource "aws_instance" "t_webserver3" {
  ami = "ami-00874d747dde814fa"
  instance_type = "t2.micro"
  key_name = "nginx"
  security_groups = [aws_security_group.t_instancesg.id]
  subnet_id = aws_subnet.t_publicsubnet3.id
  availability_zone = "us-east-1c"

  provisioner "local-exec" {
    command = "echo '${self.public_ip}' >> /vagrant/Terraform_MiniProject/host-inventory"
  }

  tags = { 
    Name = "t_webserver1"
    source = "terraform"
  }
}


# USING LOCAL PROVIDER TO SAVE A FILE


# CREATING AN APPLICATION LOAD BALANCER
resource "aws_lb" "t_loadbalancer" { 
  name = "t-loadbalancer"
  internal = false
   load_balancer_type = "application"
   security_groups = [aws_security_group.t_loadbalancersg.id]
   subnets = [aws_subnet.t_publicsubnet1.id, aws_subnet.t_publicsubnet2.id, aws_subnet.t_publicsubnet3.id]
   enable_deletion_protection = false
   depends_on =[aws_instance.t_webserver1, aws_instance.t_webserver2, aws_instance.t_webserver3]
}

# LOAD BALANCER TARGET GROUPS
resource "aws_lb_target_group" "t_targetgroup" {
  name = "t-targetgroup"
  target_type = "instance"
  port = 80 
  protocol = "HTTP"
  vpc_id = aws_vpc.tvpc.id

  health_check{
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

# LISTENERS
resource "aws_lb_listener" "t_listener" { 
  load_balancer_arn = aws_lb.t_loadbalancer.arn
  port = "80"
  protocol = "HTTP"

  default_action { 
    type  = "forward"
    target_group_arn = aws_lb_target_group.t_targetgroup.arn
  }
}

resource "aws_lb_listener_rule" "t_listenerrule" {
  listener_arn = aws_lb_listener.t_listener.arn 
  priority = 1

  action { 
    type = "forward"
    target_group_arn = aws_lb_target_group.t_targetgroup.arn
  }

  condition {
    path_pattern{
      values = ["/"]
    }
  }
}

# CONNECTING TARGET GROUPS TO LOADBALANCER
resource "aws_lb_target_group_attachment" "t_tg_attachment1" {
  target_group_arn = aws_lb_target_group.t_targetgroup.arn
  target_id = aws_instance.t_webserver1.id 
  port = 80
}

resource "aws_lb_target_group_attachment" "t_tg_attachment2" {
  target_group_arn = aws_lb_target_group.t_targetgroup.arn
  target_id = aws_instance.t_webserver2.id 
  port = 80
}

resource "aws_lb_target_group_attachment" "t_tg_attachment3" {
  target_group_arn = aws_lb_target_group.t_targetgroup.arn
  target_id = aws_instance.t_webserver3.id 
  port = 80
}


# ALB OUTPUTS


output "elb_target_group_arn" {
    value = aws_lb_target_group.t_targetgroup.arn
}

output "elb_load_balancer_dns_name" {
    value = aws_lb.t_loadbalancer.dns_name
}

output "elastic_load_balancer_zone_id" {
    value = aws_lb.t_loadbalancer.zone_id
}