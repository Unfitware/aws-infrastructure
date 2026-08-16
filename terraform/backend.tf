terraform {
  backend "s3" {
    bucket       = "my-project-tfstate"
    key          = "dev-tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

