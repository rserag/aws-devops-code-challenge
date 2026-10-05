output "trail_arn" {
  value = aws_cloudtrail.this.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.logs.id
}

output "monitoring" {
  value = {
    log_group_name = aws_cloudwatch_log_group.cloudtrail.name
    alarm_name     = aws_cloudwatch_metric_alarm.unauthorized.alarm_name
  }
}
