variable "region" {
  default     = "us-east-1"
  description = "AWS Region for the VPC "

}
variable "vpc-cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR for the VPC"

}
variable "public-subnet-ip" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.2.0/24"]

}
variable "private-subnet-ip" {
  type    = list(any)
  default = ["10.0.3.0/24", "10.0.4.0/24"]

}
variable "ec2-instance-type" {
  default     = "t3.micro"
  description = "EC2 instance type"

}
variable "public-key-name" {
  default = "tekup-user"

}

variable "asg-min" {
  default = 2

}
variable "asg-max" {
  default = 2

}

variable "asg-des" {
  default = 2

}
