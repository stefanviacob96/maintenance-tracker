variable "aws_region" {
  description = "AWS region where the EC2 instance will be created"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging AWS resources"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging AWS resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance"
  type        = string
}

variable "app_port" {
  description = "Port exposed by the Maintenance Tracker app"
  type        = number
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name to use for SSH access"
  type        = string
}
