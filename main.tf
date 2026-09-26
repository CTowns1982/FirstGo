terraform {
  required_version = ">= 1.7.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The provider automatically picks up the env variables from the GitHub Runner
provider "aws" {
  region = "eu-west-2"
}

# A simple check resource that doesn't cost money
resource "aws_vpc" "pipeline_test" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "GitHubActionsTestVPC"
  }
}