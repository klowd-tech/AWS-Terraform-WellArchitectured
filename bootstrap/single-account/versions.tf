terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.52.0"
    }
    local = {
      source = "hashicorp/local"
      version = "= 2.1.0"

    }
  }
  required_version = "~> 1.5.6"
}
