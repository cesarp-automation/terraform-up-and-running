##########################################################################################
### providers
##########################################################################################
provider "aws" {
  region = "us-east-1"
}

##########################################################################################
### input variables
##########################################################################################
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

##########################################################################################
### resources
##########################################################################################
resource "aws_launch_configuration" "example" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF


  tags {
    Name = "terraform-example"
  }
  image_id = ""
}

resource "aws_security_group" "instance" {
  name = "terraform-instance-example"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}



##########################################################################################
### Output Variables
##########################################################################################
output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}