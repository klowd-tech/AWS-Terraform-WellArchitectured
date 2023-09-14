
locals {
  region              = var.region
  account_environment = "${var.company}-${var.environment}"
  terraform_user      = "${var.environment}-${var.terraform_user}"
  state_bucket        = "${var.company}-${var.bucket_purpose}-${var.environment}"
  logging_bucket      = "${var.company}-${var.bucket_purpose}-${var.log_name}-${var.environment}"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Environment = local.account_environment
    Project     = "${var.company}-Infrastructure"
  }
}
