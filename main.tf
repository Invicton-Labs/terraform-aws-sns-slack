terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.49"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_id" "sns_sqs_name" {
  byte_length = 8
}

locals {
  sns_sqs_name      = "slack${var.name != "" ? "-${var.name}" : ""}-${random_id.sns_sqs_name.hex}"
  sns_sqs_name_fifo = "${local.sns_sqs_name}${var.fifo ? ".fifo" : ""}"
}
