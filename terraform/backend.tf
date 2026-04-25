terraform {
  backend "s3" {
    bucket         = "j64364-tfstate"
    key            = "dev-tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "j64364-tfstate-lock"
  }
}

