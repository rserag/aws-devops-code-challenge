resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = var.cloudwatch_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.name_prefix}-cloudtrail-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name_prefix}-cloudtrail-cloudwatch"
  role = aws_iam_role.cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_*"
    }]
  })
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized" {
  name           = "${var.name_prefix}-unauthorized-api"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name          = "UnauthorizedApiCalls"
    namespace     = "${var.name_prefix}/Security"
    value         = "1"
    default_value = 0
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized" {
  alarm_name        = "${var.name_prefix}-unauthorized-api"
  alarm_description = "One or more denied AWS API calls within five minutes."

  namespace   = "${var.name_prefix}/Security"
  metric_name = "UnauthorizedApiCalls"
  statistic   = "Sum"
  unit        = "Count"
  period      = 300

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_action_arns

  tags = local.common_tags
}
