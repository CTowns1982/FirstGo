terraform {
  required_version = ">= 1.7.5"

  backend "s3" {
    bucket         = "ctprodterraform" # Must be pre-created in AWS
    key            = "environments/production/terraform.tfstate"
    region         = "eu-west-2"
  }
  
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
resource "aws_vpc" "pipeline_test1" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "GitHubActionsTestVPC"
  }
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "aurora-cluster-demo"
  engine                  = "aurora-postgresql"
  availability_zones      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  database_name           = "mydb"
  master_username         = "foo"
  master_password         = "12345678"
  backup_retention_period = 5
  database_insights_mode      = "standard"
performance_insights_enabled = false
  preferred_backup_window = "07:00-09:00"
}
