variable "region" {
  description = "Provider region"
  type        = string
  default     = "us-east-2"
}
variable "company" {
  description = "The company name to add to naming convention."
  type        = string
}


variable "environment" {
  description = "work environment - sandbox | dev | uat |  prod"
  type        = string
}

variable "log_retention" {
  description = "Log retention of access logs of state bucket."
  default     = 90
  type        = number
}

variable "bucket_purpose" {
  description = "Name to identify the bucket's purpose"
  default     = "terraform"
  type        = string
}

variable "log_name" {
  description = "Log name"
  default     = "logs"
  type        = string
}

variable "log_bucket_versioning" {
  description = "A string that indicates the versioning status for the log bucket."
  default     = "Disabled"
  type        = string
  validation {
    condition     = contains(["Enabled", "Disabled", "Suspended"], var.log_bucket_versioning)
    error_message = "Valid values for versioning_status are Enabled, Disabled, or Suspended."
  }
}

variable "state_bucket_tags" {
  type        = map(string)
  default     = { Automation : "Terraform" }
  description = "Tags to associate with the bucket storing the Terraform state files"
}

variable "log_bucket_tags" {
  type        = map(string)
  default     = { Automation : "Terraform", Logs : "Terraform" }
  description = "Tags to associate with the bucket storing the Terraform state bucket logs"
}

variable "terraform_user" {
  description = "The username for the infrastructure provisioning user."
  type        = string
  default     = "terraform-user"
}

variable "terraform_user_permissions" {
  description = "The permissions for the infrastructure provisioning."
  type        = list(string)
  default     = ["s3:CreateBucket"]
}
