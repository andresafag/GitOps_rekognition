variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "prometheus-yace"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.small"
}

variable "key_name" {
  description = "Optional key pair name for SSH access"
  type        = string
  default     = ""
}

variable "allowed_cidr" {
  description = "CIDR to allow inbound access to Prometheus (port 9090)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "prometheus_port" {
  description = "Port Prometheus listens on"
  type        = number
  default     = 9090
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for environment"
  type        = string
  default     = "us-east-1"
}

variable "iam_instance_profile" {
  description = "Optional instance profile name to attach to the EC2 instance"
  type        = string
  default     = ""
}
