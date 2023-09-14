
provider "aws" {
  region = local.region
  default_tags {
    tags = {
      owner = "Sports Inference - Ubet"
    }
  }
}
