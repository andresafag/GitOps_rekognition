terraform {
  backend "s3" {
    bucket  = "face-rekognition-terraform-state"
    key     = "global/s3-lambda-rekognition/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
