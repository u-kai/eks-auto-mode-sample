variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_private_subnets" {
  description = "The CIDR blocks for the private subnets"
  type        = list(map(string))
  default = [
    {
      name = "for-node0"
      cidr = "10.0.1.0/24"
      az   = "ap-northeast-1a"
    },
    {
      name = "for-node1"
      cidr = "10.0.2.0/24"
      az   = "ap-northeast-1c"
    }
  ]
}

variable "cluster_subnets" {
  description = "The CIDR blocks for the cluster subnets"
  type        = list(map(string))
  default = [
    {
      cidr = "10.0.100.0/24"
      az   = "ap-northeast-1a"
    },
    {
      cidr = "10.0.101.0/24"
      az   = "ap-northeast-1c"
    },
  ]

}

variable "public_subnets" {
  description = "The CIDR blocks for the public subnets"
  type        = list(map(string))
  default = [
    {
      name = "for-nlb"
      cidr = "10.0.3.0/24"
      az   = "ap-northeast-1a"
    },
    {
      name = "for-alb"
      cidr = "10.0.4.0/24"
      az   = "ap-northeast-1c"
    }
  ]
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-northeast-1"
}

