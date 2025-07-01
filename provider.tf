
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.2.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Environment     = local.env.environment
      Service         = local.env.sid
    }
  }
}

terraform {
  backend "s3" {
    # create this bucket manually
    bucket = "terraform-state-creative-tech"
    key    = "elearn.tfstate"
    region = "eu-west-1"

    # Enable state locking
    # create this table with partitionKey LockID
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "opensearch" {
  url        = aws_opensearchserverless_collection.collection.collection_endpoint
  aws_region = "eu-west-1"

  healthcheck = false
}