variable "aws_access_key" {
  type = "string"
  description = "AWS access key"
}

variable "aws_secret_key" {
  type = "string"
  description = "AWS secret key"
}

variable "region" {
  description = "The AWS region to deploy into."
  default     = "us-east-2"
}

variable "debug_mode" {
  type = "string"
  description = "Enable debuging log?"
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
  default     = "GoTerraId"
}

variable "dynamodb_tag_name" {
  description = "DynamoDB table tag name"
  type = "string"
}

variable "dynamodb_tag_env" {
  description = "Environment tag for DynamoDB table"
  type = "string"
}