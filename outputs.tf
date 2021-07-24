output "sns_topic" {
  description = "The SNS topic that was created."
  value       = aws_sns_topic.slack
}

output "sns_kms_key" {
  description = "The KMS key that was created for the SNS topic to use."
  value       = aws_kms_key.sns
}

output "sqs_queue" {
  description = "The SQS queue that was created."
  value       = length(aws_sqs_queue.slack) > 0 ? aws_sqs_queue.slack[0] : null
}

output "sqs_kms_key" {
  description = "The KMS key that was created for the SQS queue to use."
  value       = length(aws_kms_key.sqs) > 0 ? aws_kms_key.sqs[0] : null
}

output "sqs_queue_policy" {
  description = "The resource policy that was applied to the SQS queue."
  value       = length(aws_sqs_queue_policy.slack) > 0 ? aws_sqs_queue_policy.slack[0] : null
}

output "lambda_function" {
  description = "The Lambda function that was created."
  value       = module.slack_lambda.lambda
}
