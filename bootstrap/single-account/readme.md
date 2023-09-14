# Single account Bootstrap \[Terraform - AWS\]

This is a solution for solving the 🐓 and 🥚 problem for implementing terraform support for AWS accounts: How do you Terraform the remote state bucket & user with the right infrastructure generation policies?

It takes the approach of keeping a local statefile in the repo that only manages these resources:

- AWS IAM user for provisioning infrastructure
- S3 bucket for remote state file
- S3 bucket for storing state bucket access logs

References:

- https://github.com/trussworks/terraform-aws-bootstrap

## Requirements

| Name                                | Version     |
| ----------------------------------- | ----------- |
| [terraform](#requirement_terraform) | \>= v1.1.9  |
| [aws cli](#requirement_aws)         | \>=v1.22.61 |

## Providers

| Name                 | Version         |
| -------------------- | --------------- |
| [aws](#provider_aws) | \>= 3.0, \< 4.0 |

## Resources

| Name                                                                                                   | Type     |
| ------------------------------------------------------------------------------------------------------ | -------- |
| [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_iam_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user)   | resource |

## Inputs

| Name                                                  | Description                                                         | Type          | Default       | Required |
| ----------------------------------------------------- | ------------------------------------------------------------------- | ------------- | ------------- | -------- |
| [company](#input_company)                             | The company name.                                                   | `string`      | n/a           | yes      |
| [bucket_purpose](#input_bucket_purpose)               | Name to identify the bucket's purpose                               | `string`      | `"terraform"` | no       |
| [log_bucket_versioning](#input_log_bucket_versioning) | Bool for toggling versioning for log bucket                         | `bool`        | `false`       | no       |
| [log_name](#input_log_name)                           | Log name (for backwards compatibility this can be modified to logs) | `string`      | `"log"`       | no       |
| [log_retention](#input_log_retention)                 | Log retention of access logs of state bucket.                       | `number`      | `90`          | no       |
| [state_bucket_tags](#input_state_bucket_tags)         | Tags to associate with the bucket storing the Terraform state files | `map(string)` | {             |

"Automation": "Terraform"  
} | no |

## Outputs

| Name                                     | Description             |
| ---------------------------------------- | ----------------------- |
| [logging_bucket](#output_logging_bucket) | The logging_bucket name |
| [state_bucket](#output_state_bucket)     | The state_bucket name   |

## Bootstrapping

```
terraform init && terraform plan
# Review output of plan
terraform apply
```

## Using the backend

After provisioning the S3 bucket & user. You can create the `state.tf` file in the environment terraform path to use it.

```
terraform {
  required_version = "~> 0.13"

  backend "s3" {
    bucket         = "bucket-name"
    key            = "${environment}/terraform/.tfstate"
    region         = "region"
    encrypt        = "true"
  }
}
```
