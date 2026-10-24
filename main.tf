terraform {
  required_version = ">= 1.7.5"

  backend "s3" {
    bucket = "ctprodterraform" # Must be pre-created in AWS
    key    = "environments/production/terraform.tfstate"
    region = "eu-west-2"
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

# data "aws_caller_identity" "current" {}

# data "aws_region" "current" {}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.pipeline_test1.id

  tags = {
    Name = "RestrictedDefaultSG"
  }
}

# resource "aws_kms_key" "cloudwatch" {
#   description         = "KMS key for VPC Flow Logs"
#   enable_key_rotation = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "EnableIAMPermissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "AllowCloudWatchLogs"
#         Effect = "Allow"
#         Principal = {
#           Service = "logs.${data.aws_region.current.name}.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ]
#         Resource = "*"
#         Condition = {
#           ArnEquals = {
#             "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/pipeline-test"
#           }
#         }
#       }
#     ]
#   })
# }

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/pipeline-test"
  retention_in_days = 365
  # kms_key_id        = aws_kms_key.cloudwatch.arn
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "pipeline-test-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.pipeline_test1.id
}

# resource "aws_rds_cluster" "postgresql" {
#   cluster_identifier      = "aurora-cluster-demo"
#   engine                  = "aurora-postgresql"
#   availability_zones      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
#   database_name           = "mydb"
#   master_username         = "foo"
#   master_password         = "12345678"
#   backup_retention_period = 5
#   database_insights_mode      = "advanced"
#   performance_insights_enabled = true
#   performance_insights_retention_period = 465
#   preferred_backup_window = "07:00-09:00"
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_postgres.name
# }

# resource "aws_rds_cluster_instance" "writer" {
#   cluster_identifier = aws_rds_cluster.postgresql.id
#   instance_class     = "db.t4g.medium"
#   engine             = aws_rds_cluster.postgresql.engine
#   engine_version     = aws_rds_cluster.postgresql.engine_version
#   apply_immediately = true
# }

# resource "aws_rds_cluster_parameter_group" "aurora_postgres" {
#   name        = "aurora-postgres17-custom"
#   family      = "aurora-postgresql17"
#   description = "Custom parameter group for Aurora PostgreSQL 17"

#   parameter {
#     name         = "shared_preload_libraries"
#     value        = "pg_stat_statements,pgaudit"
#     apply_method = "pending-reboot"
#   }

#   parameter {
#     name         = "pgaudit.log"
#     value        = "write,ddl,role"
#     apply_method = "immediate"
#   }

#   parameter {
#     name         = "log_connections"
#     value        = "1"
#     apply_method = "immediate"
#   }

#   parameter {
#     name         = "log_disconnections"
#     value        = "1"
#     apply_method = "immediate"
#   }
# }