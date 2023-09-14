
resource "aws_s3_bucket" "terraform_bucket" {
  bucket = local.state_bucket

  count = 1

  tags = local.common_tags
}

resource "aws_s3_bucket_acl" "terraform_bucket_acl" {
  bucket = aws_s3_bucket.terraform_bucket[0].id
  acl    = "private"
}


resource "aws_s3_bucket_logging" "logging" {
  bucket = aws_s3_bucket.terraform_bucket[0].id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
resource "aws_s3_bucket" "log_bucket" {
  bucket = local.logging_bucket

  tags = local.common_tags

}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "private"
}

# put policy on bucket
resource "aws_s3_bucket_policy" "terraform_bucket_policy" {
  bucket = aws_s3_bucket.terraform_bucket[0].id
  policy = data.aws_iam_policy_document.terraform_bucket_policy_document.json
}

# bucket policy
data "aws_iam_policy_document" "terraform_bucket_policy_document" {
  statement {
    sid = "User List Bucket"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.terraform_user.arn]
    }

    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.terraform_bucket[0].arn # bucket
    ]
  }
  statement {
    sid = "User Access state file"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.terraform_user.arn]
    }

    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform_bucket[0].arn}/${var.environment}/terraform/.tfstate*" # state file
    ]
  }
}
