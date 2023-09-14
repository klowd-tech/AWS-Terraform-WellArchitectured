/* 
  setup the infrastructure provisioning user
 */
resource "aws_iam_user" "terraform_user" {
  name = local.terraform_user
  tags = local.common_tags

}

resource "aws_iam_user_policy_attachment" "terraform_user_policy_attachment" {
  user       = aws_iam_user.terraform_user.name
  policy_arn = aws_iam_policy.terraform_user_policy.arn
}

resource "aws_iam_policy" "terraform_user_policy" {
  name        = "${local.terraform_user}-policy"
  description = "Set permissions for creating different pieces of infrastructure"

  policy = data.aws_iam_policy_document.terraform_user_policy_document.json

}

data "aws_iam_policy_document" "terraform_user_policy_document" {
  override_policy_documents = [
    data.aws_iam_policy_document.s3_policy_document.json,
    data.aws_iam_policy_document.permissions_policy_document.json
    # add policy documents here
  ]

}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["arn:aws:s3:::*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.terraform_bucket[0].arn}/${var.environment}/terraform/.tfstate*" # state file
    ]
    effect = "Allow"
  }

}

data "aws_iam_policy_document" "permissions_policy_document" {
  statement {
    actions   = var.terraform_user_permissions
    resources = ["*"]
    effect    = "Allow"
  }

}
