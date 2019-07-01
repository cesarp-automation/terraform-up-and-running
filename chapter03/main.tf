provider "aws" {
  region     = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

//# Create backet and DynamoDB table before migrating state to bucket and use lockickg
//terraform {
//  backend "s3" {
//    bucket  = "terraform-up-and-running-tfstate"
//    region  = "us-east-1"
//    key     = "global/s3/terraform.tfstate"
//    encrypt = true
//    dynamodb_table = "terraform-state-lock-dynamo"
//    profile = "myaws"   # ~/.aws/credentials
//  }
//}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data       = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p "${var.server_port}" &
        EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "instance" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  max_size = 10
  min_size = 2

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name                = "terraform-asg-example"
  availability_zones  = ["${data.aws_availability_zones.all.names}"]
  security_groups     = ["${aws_security_group.elb.id}"]

  "listener" {
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 3
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-up-and-running-tfstate"
//  force_destroy = true # enable if not empty bucket has to be deleted. 1. apply, 2. destroy

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "terraform-state-lock-dynamo"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}


################################################################################################
### VARIABLES
################################################################################################

### AWS Provider ###
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable  "server_port" {
  description = "The port the server will use for HTTP request"
  default = 8080
}

################################################################################################
### DATA SOURCES
################################################################################################

data "aws_availability_zones" "all" {}

################################################################################################
### OUTPUTS
################################################################################################

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform-state.arn}"
}