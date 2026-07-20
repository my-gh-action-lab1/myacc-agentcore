terraform {
  backend "s3" {
    bucket  = "dan-terraform-101"
    key     = "myacc-agentcore/base-infra/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
