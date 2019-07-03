# Create backet and DynamoDB table before migrating state to bucket and use lockickg
terraform {
  backend "s3" {
    bucket  = "terraform-up-and-running-tfstate"
    region  = "us-east-1"
    key     = "stage/services/webserver-cluster/terraform.tfstate"
    encrypt = true
    dynamodb_table = "terraform-state-lock-dynamo"
    profile = "myaws"   # ~/.aws/credentials
  }
}

################################################################################################
### DATA SOURCES
################################################################################################

data "aws_availability_zones" "all" {}

################################################################################################
### RESOURCES
################################################################################################

resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = "${var.instance_type}"
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

  max_size = "${var.max_size}"
  min_size = "${var.min_size}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}"
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
  name = "${var.cluster_name}-elb"

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