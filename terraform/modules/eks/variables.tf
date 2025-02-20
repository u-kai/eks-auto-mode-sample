variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-auto-mode-sample"
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "eks_version" {
  description = "The ID of the VPC"
  type        = string
  default     = "1.31"
}


variable "cluster_security_group_id" {
  description = "The ID of the security group for the EKS cluster"
  type        = string
}
