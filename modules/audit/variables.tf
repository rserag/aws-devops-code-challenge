variable "name_prefix" {
  description = "Prefix for audit resource names."
  type        = string
}

variable "log_bucket_name" {
  description = "Globally unique bucket name for CloudTrail logs."
  type        = string
}

variable "tags" {
  description = "Tags applied to audit resources."
  type        = map(string)
  default     = {}
}

variable "cloudwatch_retention_days" {
  type    = number
  default = 30
}

variable "alarm_action_arns" {
  description = "Notification destinations, such as SNS topic ARNs."
  type        = list(string)
  default     = []
}
