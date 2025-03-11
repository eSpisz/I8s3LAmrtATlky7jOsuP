terraform {
  backend "s3" {
    bucket = "bounty-hunter"
    key    = "terraform/terraform.tfstate"
    region = "eu-central-1"
  }
}
