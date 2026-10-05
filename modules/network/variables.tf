variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "subnets" {
  description = "Subnets keyed by names."

  type = map(object({
    cidr_block        = string
    availability_zone = string
    tier              = string
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnets) :
      contains(["public", "application", "database"], subnet.tier)
    ])

    error_message = "Subnet tier must be public, application, or database."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "flow_log_retention_days" {
  description = "Number of days to retain VPC flow logs."
  type        = number
  default     = 7
}
