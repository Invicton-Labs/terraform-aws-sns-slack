variable "name" {
  description = "An optional name to be used for the SQS, SNS, and Lambda resources."
  type        = string
  default     = ""
}

variable "sns_kms_resource_policy" {
  description = "A JSON-encoded resource policy to apply to the KMS CMK used for encrypting the SNS queue."
  type        = string
  default     = ""
}

variable "sqs_kms_resource_policy" {
  description = "A JSON-encoded resource policy to apply to the KMS CMK used for encrypting the SQS queue."
  type        = string
  default     = ""
}

variable "sns_tags" {
  description = "Tags to apply to the SNS topic."
  type        = map(string)
  default     = {}
}

variable "sqs_tags" {
  description = "Tags to apply to the SQS queue."
  type        = map(string)
  default     = {}
}

variable "lambda_tags" {
  description = "Tags to apply to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "sqs_queue_policy" {
  description = "An optional resource policy (in JSON format) to apply to the SQS queue. Use this if you want to be able to publish to the SQS queue directly and skip the SNS topic. Note that you'll also need to provide the `sqs_kms_resource_policy` input variable to allow other services/accounts/roles to use the encryption key for publishing to the SQS queue."
  type        = string
  default     = ""
}

variable "webhook" {
  description = "The Slack webhook to post the message to."
  type        = string
}


variable "lambda_logs_lambda_subscriptions" {
  description = "A list of configurations for Lambda subscriptions to the CloudWatch Logs Group for the Lambda function that sends messages to Slack. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "lambda_logs_non_lambda_subscriptions" {
  description = "A list of configurations for non-Lambda subscriptions to the CloudWatch Logs Group for the Lambda function that sends messages to Slack. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), `role_arn` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "sns_success_logs_lambda_subscriptions" {
  description = "A list of configurations for Lambda subscriptions to the CloudWatch Logs Group for success logs for the SNS topic. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "sns_success_logs_non_lambda_subscriptions" {
  description = "A list of configurations for non-Lambda subscriptions to the CloudWatch Logs Group for success logs for the SNS topic. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), `role_arn` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "sns_failure_logs_lambda_subscriptions" {
  description = "A list of configurations for Lambda subscriptions to the CloudWatch Logs Group for failure logs for the SNS topic. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "sns_failure_logs_non_lambda_subscriptions" {
  description = "A list of configurations for non-Lambda subscriptions to the CloudWatch Logs Group for failure logs for the SNS topic. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), `role_arn` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "success_logs_sample_rate" {
  description = "The percentage of SNS successes to sample for logging."
  type        = number
  default     = 0
}
variable "success_logs_retention_in_days" {
  description = "The number of days to retain SNS success logs. Default: forever."
  type        = number
  default     = 0
}
variable "failure_logs_retention_in_days" {
  description = "The number of days to retain SNS failure logs. Default: forever."
  type        = number
  default     = 0
}
variable "fifo" {
  description = "Whether to configure the system using FIFO SNS topics and SQS queues. Guarantees exactly-once message delivery, but cannot be used with Cloudwatch Alarms or other AWS-managed message producers (since they do not provide the required MessageGroupId parameter)."
  type        = bool
  default     = false
}
variable "content_based_deduplication" {
  description = "Whether to use content-based deduplication for the FIFO SNS topic and FIFO SQS queue. Only applies if the `fifo` input variable is `true`."
  type        = bool
  default     = false
}
variable "lambda_filename" {
  description = "The ZIP archive filename to use for the Lambda sending function. If provided, it will be used to send all messages to Slack. Otherwise, a default Lambda will be used that posts all messages as-is to the Slack endpoint."
  type        = string
  default     = null
}
variable "lambda_handler" {
  description = "The handler to call for the Lambda, if `lambda_filename` was specified."
  type        = string
  default     = "main.lambda_handler"
}
variable "lambda_runtime" {
  description = "The runtime to use for the Lambda, if `lambda_filename` was specified."
  type        = string
  default     = "python3.8"
}
