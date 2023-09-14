region                     = "eu-central-1"
company                    = "company-name"
environment                = "staging"
log_retention              = 90
bucket_purpose             = "logging"
log_name                   = "company-name-environment-log"
log_bucket_versioning      = "Enabled"
state_bucket_tags          = { Automation : "Terraform" }
log_bucket_tags            = { Automation : "Terraform", Logs : "Terraform" }
terraform_user             = "terraform-user"
terraform_user_permissions = ["s3:CreateBucket"]