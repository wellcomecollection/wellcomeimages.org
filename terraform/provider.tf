provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::130871440101:role/experience-developer"
  }
}

locals {
  default_tags = {
    TerraformConfigurationURL = "https://github.com/wellcomecollection/wellcomeimages/tree/master/terraform"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dns"

  assume_role {
    role_arn = "arn:aws:iam::267269328833:role/wellcomecollection-assume_role_hosted_zone_update"
  }
}
