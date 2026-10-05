variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "application_subnet_ids" {
  description = "Application subnet IDs keyed by subnet name."
  type        = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ami_id" {
  description = "AMI used for the private instance."
  type        = string
}

variable "instance_subnet_id" {
  description = "Application subnet containing the instance."
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
