provider "aws" {
  region = "us-east-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_accountnumber}:role/dev-terraform-role"
  }
}

