variable "awsRegion" {
  default = "eu-west-1"
}

variable "client" {
  type    = string
}

variable "environment" {
  type    = string
}

variable "region" {
  type    = string
}

variable "account_id" {
  type    = string
}

variable "dynamodb_table_sns_topic_monitoring_arn" {
  type    = string
}

variable "dms_task_replication_instance_arn" {
  type    = list(string)
}

variable "dms_task_UK_source_endpoint_arn" {
  type    = string
}

variable "dms_task_US_source_endpoint_arn" {
  type    = string
}

variable "dms_task_DE_source_endpoint_arn" {
  type    = string
}

variable "dms_task_VN_source_endpoint_arn" {
  type    = string
}

variable "dms_task_HK_source_endpoint_arn" {
  type    = string
}

variable "dms_task_HLD_source_endpoint_arn" {
  type    = string
}

variable "dms_task_CON_source_endpoint_arn" {
  type    = string
}

variable "dms_task_target_endpoint_arn" {
  type    = string
}

variable "dms_task_log_group" {
  type    = string
}

variable "dms_task_sns_topic_monitoring_arn" {
  type    = string
}

variable "dms_task_alarm_period" {
  type    = number
  default = 300
}

/* LAMBDA CONFIG */

variable "lambda_function_enable_vpc_config" {
  description = "Whether to deploy this lambda to a VPC or not. If true, lambda_vpc_config defines the config.  Default to true"
  default     = true
}

variable "lambda_function_vpc_config" {
  description = "Whether to deploy this lambda to a VPC or not. If true, lambda_vpc_config defines the config."
  type        = map(list(string))
}

variable "lambda_function_memory_size" {
  description = "Amount of memory in MB your lambda function can use at runtime.  Default to 512"
  type        = number
  default     = 512
}

variable "lambda_function_name_prefix" {
  description = "A prefix for the lambda function's name to help namespace the same logical function into isolated 'stacks' e.g LSS_ or LSS_featureX_"
  type        = string
  default     = ""
}

variable "lambda_function_kms_key_arn" {
  description = "The lambdas KMS key arn used for encryption"
  type        = string
}

variable "lambda_function_sns_topic_monitoring_arn" {
  description = "The monitoring SNS topic(s) to send tripped alerts to for support"
  type        = string
}

variable "lambda_function_source_base_path" {
  description = "The zip source file path containing the lambda deployment package. Default assumes normal provider dir structure setup.  refer README"
  type        = string
}

variable "lambda_function_existing_execute_role" {
  description = "Is there an existing execute lambda role created to use?  If non-empty string then use this and ignore other IAM.  Dont remove default."
  type        = string
}

variable "lambda_function_env_vars" {
  description = "Global lambda envars"
  type        = map(string)
}

/* KINESIS CONFIG */
variable "kinesis_stream_retention" {
  description = "Stream retention"
  type        = number
  default     = 24
}

variable "kinesis_stream_shard_level_metrics" {
  description = "Shard level metrics"
  type        = list(string)
}

variable "kinesis_stream_kms_key_id" {
  description = "The kinesis KMS key arn used for encryption"
  type        = string
}

variable "kinesis_stream_sns_topic_monitoring_arn" {
  description = "The monitoring SNS topic(s) to send tripped alerts to for support"
  type        = string
}
