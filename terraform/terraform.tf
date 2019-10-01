terraform {
  required_version = ">= 0.11.10"

  backend "s3" {
    role_arn = "arn:aws:iam::130871440101:role/experience-developer"

    key            = "build-state/wellcomeimages.tfstate"
    dynamodb_table = "terraform-locktable"
    region         = "eu-west-1"
    bucket         = "wellcomecollection-infra"
  }
}

data "terraform_remote_state" "router" {
  backend = "s3"

  config {
    role_arn = "arn:aws:iam::130871440101:role/experience-developer"

    bucket = "wellcomecollection-infra"
    key    = "build-state/router.tfstate"
    region = "eu-west-1"
  }
}
