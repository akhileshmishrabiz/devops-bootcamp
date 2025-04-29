
# Create security group for endpoints
resource "aws_security_group" "endpoint_sg" {
  name        = "endpoint-sg"
  description = "Allow TLS inbound traffic for VPC endpoints"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "endpoint-sg"
  }
}

# Create Interface Endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = "com.amazonaws.ap-south-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [data.aws_subnet.selected.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]

  tags = {
    Name = "ssm-endpoint"
  }
}

# Create Interface Endpoint for EC2 Messages
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = "com.amazonaws.ap-south-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [data.aws_subnet.selected.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]

  tags = {
    Name = "ec2messages-endpoint"
  }
}

# Create Interface Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = data.aws_vpc.selected.id
  service_name        = "com.amazonaws.ap-south-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [data.aws_subnet.selected.id]
  security_group_ids  = [aws_security_group.endpoint_sg.id]

  tags = {
    Name = "ssmmessages-endpoint"
  }
}



# Output the endpoint IDs
output "ssm_endpoint_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "ec2messages_endpoint_id" {
  value = aws_vpc_endpoint.ec2messages.id
}

output "ssmmessages_endpoint_id" {
  value = aws_vpc_endpoint.ssmmessages.id
}