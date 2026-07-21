terraform {
  backend "s3" {
    bucket  = "dan-terraform-101"
    key     = "myacc-agentcore/watchy/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}
