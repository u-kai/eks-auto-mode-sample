terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    key    = "eks-auto-mode-sample/apps/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

// sampleコンテナのリポジトリを作成
resource "aws_ecr_repository" "pod_identity_sample" {
  name = "pod-identity-sample"
}

// sampleコンテナに与えるAWSの権限を作成
resource "aws_eks_pod_identity_association" "pod_identity_sample" {
  cluster_name    = var.cluster_name
  namespace       = "default"
  service_account = "pod-identity-sample"
  role_arn        = aws_iam_role.pod_identity_sample.arn
}

resource "aws_iam_role" "pod_identity_sample" {
  name = "pod-identity-sample"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "pods.eks.amazonaws.com"
        },
        Action = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pod_identity_sample" {
  policy_arn = aws_iam_policy.pod_identity_sample.arn
  role       = aws_iam_role.pod_identity_sample.name
}

resource "aws_iam_policy" "pod_identity_sample" {
  name        = "pod-identity-sample"
  description = "Policy for pod-identity-sample"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["sts:GetCallerIdentity"],
        Resource = "*"
      }
    ]
  })
}
