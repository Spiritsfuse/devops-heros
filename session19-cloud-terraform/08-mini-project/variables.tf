variable "aws_region" {
  description = "AWS region for the Session 19 infrastructure project."
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bucket_name" {
  description = "S3 bucket name for application storage"
  type        = string
  default     = "spirits5510-session19-storage"
}
