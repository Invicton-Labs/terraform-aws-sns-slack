// Add to the policy to enable the SNS topic to send to it
data "aws_iam_policy_document" "kms_sqs" {
  source_json = var.sqs_kms_resource_policy
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
  statement {
    sid = "__SNS"
    actions = [
      "kms:GenerateDataKey",
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

resource "aws_kms_key" "sqs" {
  count                   = var.fifo ? 1 : 0
  description             = "${local.sns_sqs_name}-sqs"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_sqs.json
}

resource "aws_sqs_queue" "slack" {
  count                       = var.fifo ? 1 : 0
  name                        = local.sns_sqs_name_fifo
  visibility_timeout_seconds  = 30
  fifo_queue                  = var.fifo
  content_based_deduplication = var.fifo ? var.content_based_deduplication : false
  kms_master_key_id           = aws_kms_key.sqs[0].id
  tags                        = var.sqs_tags
}

// Add to the policy to enable the SNS topic to send to it
data "aws_iam_policy_document" "sqs" {
  count       = var.fifo ? 1 : 0
  source_json = var.sqs_queue_policy
  statement {
    sid = "__SNSSubscription"
    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.slack[0].arn
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_sns_topic.slack.arn
      ]
    }
  }
}

// Attach the SQS policy
resource "aws_sqs_queue_policy" "slack" {
  count     = var.fifo ? 1 : 0
  queue_url = aws_sqs_queue.slack[0].id
  policy    = data.aws_iam_policy_document.sqs[0].json
}
