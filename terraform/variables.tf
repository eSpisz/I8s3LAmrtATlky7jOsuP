data "aws_caller_identity" "current" {}

variable "region" {
  description = "The AWS region to deploy the services to"
  type        = string
  default     = "<REGION_PLACEHOLDER>"
}

variable "bucket_name" {
  description = "The name of the S3 bucket to store the results"
  type        = string
  default     = "<BUCKET_PLACEHOLDER>"
}

variable "nmap_image" {
  description = "nmap service image"
  type        = string
  default     = "<AWS_ECR_REPO_PLACEHOLDER>"
}

variable "dnsrecon_image" {
  description = "dnsrecon service image"
  type        = string
  default     = "<AWS_ECR_REPO_PLACEHOLDER>"
}

variable "ffuf_image" {
  description = "ffuf service image"
  type        = string
  default     = "<AWS_ECR_REPO_PLACEHOLDER>"
}

variable "whois_image" {
  description = "whois service image"
  type        = string
  default     = "<AWS_ECR_REPO_PLACEHOLDER>t"
}
