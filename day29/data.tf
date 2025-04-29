
# vpc id 
data "aws_vpc" "selected" {
  tags = {
    Name = "Default"
  }
}


data "aws_subnet" "selected" {
  tags = {
    Name = "RDS-Pvt-subnet-1"
  }
}