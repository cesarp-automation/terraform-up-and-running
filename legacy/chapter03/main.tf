##########################################################################################
### providers
##########################################################################################
provider "aws" {
  region = "us-east-1"
}

//# Create backet and DynamoDB table before migrating state to bucket and use lockickg
//terraform {
//  backend "s3" {
//    bucket  = "terraform-up-and-running-tfstate"
//    region  = "us-east-1"
//    key     = "global/s3/terraform.tfstate"
//    encrypt = true
//    dynamodb_table = "terraform-state-lock-dynamo"
//  }
//}

##########################################################################################
### resources
##########################################################################################

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

##########################################################################################
### output Variables
##########################################################################################

output "s3_bucket_arn" {
  value = "${aws_s3_bucket.terraform-state.arn}"
}