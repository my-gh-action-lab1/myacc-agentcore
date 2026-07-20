terraform {
  backend "s3" {
    bucket  = "dan-terraform-101"
    key     = "myacc-agentcore/base-infra/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}
