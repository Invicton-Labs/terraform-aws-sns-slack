// Create a policy that allows receiving messages from the SQS queue
data "aws_iam_policy_document" "lambda" {
  count = var.fifo ? 1 : 0
  dynamic "statement" {
    for_each = length(aws_sqs_queue.slack) > 0 ? [aws_sqs_queue.slack[0]] : []
    content {
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]
      resources = [
        statement.value.arn
      ]
    }
  }
  dynamic "statement" {
    for_each = length(aws_kms_key.sqs) > 0 ? [aws_kms_key.sqs[0]] : []
    content {
      actions = [
        "kms:Decrypt"
      ]
      resources = [
        statement.value.arn
      ]
    }
  }
}

// Create the Lambda that will post to Slack
module "slack_lambda" {
  source                   = "Invicton-Labs/lambda-set/aws"
  version                  = "0.4.0"
  edge                     = false
  source_directory         = var.lambda_filename == null ? "${path.module}/lambda-poster" : null
  archive_output_directory = var.lambda_filename == null ? "${path.module}/archives/" : null
  lambda_config = {
    filename      = var.lambda_filename
    function_name = local.sns_sqs_name
    handler       = var.lambda_filename == null ? "main.lambda_handler" : var.lambda_handler
    runtime       = var.lambda_filename == null ? "python3.8" : var.lambda_runtime
    timeout       = 30
    memory_size   = 128
    environment = {
      variables = {
        WEBHOOK = sensitive(var.webhook)
      }
    }
    tags = var.lambda_tags
  }
  role_policies                 = data.aws_iam_policy_document.lambda[*].json
  logs_lambda_subscriptions     = var.lambda_logs_lambda_subscriptions
  logs_non_lambda_subscriptions = var.lambda_logs_non_lambda_subscriptions
}

// Hook the Lambda up to the SQS queue, if we're using the FIFO system
resource "aws_lambda_event_source_mapping" "sqs" {
  count            = var.fifo ? 1 : 0
  event_source_arn = aws_sqs_queue.slack[0].arn
  function_name    = module.slack_lambda.lambda.arn
}

// Allow the SNS topic to invoke the Lambda
resource "aws_lambda_permission" "slack" {
  // Only create it if we're not doing FIFO, so the SNS will invoke the Lambda directly
  count         = var.fifo ? 0 : 1
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.slack_lambda.lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.slack.arn
}
