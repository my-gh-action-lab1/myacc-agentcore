terraform {
  backend "s3" {
    bucket  = "dan-terraform-01"
    key     = "myacc-agentcore/bootstrap-oidc/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
