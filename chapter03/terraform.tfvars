terragrunt = {

  # Configure Terragrunt to automatically store tfstate files in S3 remote_state
  remote_state {
    backend = "s3"

    config {
      encrypt   = true
      bucket    = "terraform-up-and-running-tfstate"
      key       = "global/s3/terraform.tfstate"
      region    = "us-east-1"
      dynamodb_table = "terraform-state-lock-dynamo"
    }
  }
}