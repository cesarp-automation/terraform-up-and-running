provider "aws" {
  region = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

resource "aws_instance" "example" {
  ami = "ami-40d28157"
  instance_type = "t2.micro"

  tags {
    Name  = "terraform-example"
  }
}


################################################################################################
### VARIABLES
################################################################################################

### AWS Provider ###
variable "aws_access_key" {}
variable "aws_secret_key" {}
