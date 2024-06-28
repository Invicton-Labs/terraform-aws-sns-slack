module "success_logs" {
  source  = "Invicton-Labs/log-group/aws"
  version = "~>0.4.0"

  log_group_config = {
    name              = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/${local.sns_sqs_name_fifo}"
    retention_in_days = var.success_logs_retention_in_days
  }
  lambda_subscriptions     = var.sns_success_logs_lambda_subscriptions
  non_lambda_subscriptions = var.sns_success_logs_non_lambda_subscriptions
}

module "failure_logs" {
  source  = "Invicton-Labs/log-group/aws"
  version = "~>0.4.0"

  log_group_config = {
    name              = "sns/${data.aws_region.current.name}/${data.aws_caller_identity.current.account_id}/${local.sns_sqs_name_fifo}/Failure"
    retention_in_days = var.failure_logs_retention_in_days
  }
  lambda_subscriptions     = var.sns_success_logs_lambda_subscriptions
  non_lambda_subscriptions = var.sns_success_logs_non_lambda_subscriptions
}

data "aws_iam_policy_document" "sns_role_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sns_success" {
  name               = "sns-${local.sns_sqs_name}-success"
  assume_role_policy = data.aws_iam_policy_document.sns_role_assume.json
}

resource "aws_iam_role_policy" "sns_success" {
  name   = "cloudwatch"
  role   = aws_iam_role.sns_success.id
  policy = module.success_logs.logging_policy_json
}

resource "aws_iam_role" "sns_failure" {
  name               = "sns-${local.sns_sqs_name}-failure"
  assume_role_policy = data.aws_iam_policy_document.sns_role_assume.json
}

resource "aws_iam_role_policy" "sns_failure" {
  name   = "cloudwatch"
  role   = aws_iam_role.sns_failure.id
  policy = module.failure_logs.logging_policy_json
}

// Add to the policy to enable the SNS topic to send to it
data "aws_iam_policy_document" "kms_sns" {
  source_policy_documents = [
    var.sns_kms_resource_policy
  ]
  // Allow the account the ability to administer the key
  statement {
    sid = "__Administration"
    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  // Allow SNS to use the key
  statement {
    sid = "__SNS"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "sns" {
  description             = "${local.sns_sqs_name}-sns"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_sns.json
}

resource "aws_sns_topic" "slack" {
  depends_on = [
    aws_iam_role_policy.sns_success,
    aws_iam_role_policy.sns_failure,
    module.success_logs.complete,
    module.failure_logs.complete
  ]
  name                                = local.sns_sqs_name_fifo
  display_name                        = "Slack Notifications${var.name != "" ? " ($var.name)" : ""}"
  fifo_topic                          = var.fifo
  content_based_deduplication         = var.fifo ? var.content_based_deduplication : false
  kms_master_key_id                   = aws_kms_key.sns.id
  sqs_success_feedback_sample_rate    = var.success_logs_sample_rate
  sqs_success_feedback_role_arn       = aws_iam_role.sns_success.arn
  sqs_failure_feedback_role_arn       = aws_iam_role.sns_failure.arn
  lambda_success_feedback_sample_rate = var.success_logs_sample_rate
  lambda_success_feedback_role_arn    = aws_iam_role.sns_success.arn
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_failure.arn
  tags                                = var.sns_tags
}

// Subscribe the SQS queue or the Lambda to the SNS topic
resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.slack.arn
  protocol  = var.fifo ? "sqs" : "lambda"
  endpoint  = var.fifo ? aws_sqs_queue.slack[0].arn : module.slack_lambda.lambda.arn
  // Use raw message delivery so messages can be delivered either to the SNS topic or the SQS queue and will work the same either way
  raw_message_delivery = var.fifo
}
