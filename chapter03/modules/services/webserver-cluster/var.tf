################################################################################################
### VARIABLES
################################################################################################

//### AWS Provider ###
//variable "aws_access_key" {}
//variable "aws_secret_key" {}

variable  "server_port" {
  description = "The port the server will use for HTTP request"
  default = 8080
}