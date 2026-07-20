terraform {
  backend "s3" {
    bucket  = "dan-terraform-01"
    key     = "myacc-agentcore/base-infra/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
