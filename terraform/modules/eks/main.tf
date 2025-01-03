resource "aws_eks_cluster" "main" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  bootstrap_self_managed_addons = false
  role_arn                      = aws_iam_role.cluster.arn
  version                       = var.eks_version

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy,
  ]

}

resource "aws_iam_role" "node" {
  name = "eks-sample-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


data "aws_security_group" "eks_cluster" {
  id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster" {
  security_group_id = data.aws_security_group.eks_cluster.id
  ip_protocol       = "-1"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.vpc_lattice.id
}

resource "aws_vpc_security_group_ingress_rule" "worker_nodes_vpc_lattice_ipv6" {
  security_group_id = data.aws_security_group.eks_cluster.id
  ip_protocol       = "-1"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.vpc_lattice_ipv6.id
}

data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  name = "com.amazonaws.${data.aws_region.current.name}.vpc-lattice"
}

data "aws_ec2_managed_prefix_list" "vpc_lattice_ipv6" {
  name = "com.amazonaws.${data.aws_region.current.name}.ipv6.vpc-lattice"
}

data "aws_region" "current" {}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPullOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role" "cluster" {
  name = "eks-sample-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSComputePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSNetworkingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.cluster.name
}

// eksを操作するためのIAMロールを作成
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.cluster_admin.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.cluster_admin.arn
  access_scope {
    type = "cluster"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "cluster_admin" {
  // このロールを指定してeksからトークンを取得し、kubectlなどで操作する
  name = "eks-sample-cluster-admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "cluster_admin" {
  name        = "eks-sample-cluster-admin"
  description = "Full access to EKS cluster"
  policy      = data.aws_iam_policy_document.cluster_admin.json
}

data "aws_iam_policy_document" "cluster_admin" {
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

// vpc lattice controllerのIAMロールを作成
resource "aws_eks_pod_identity_association" "vpc_lattice_controller" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "aws-application-networking-system"
  service_account = "gateway-api-controller"
  role_arn        = aws_iam_role.vpc_lattice_controller.arn
}

resource "aws_iam_role" "vpc_lattice_controller" {
  name = "VPCLatticeControllerIAMRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_lattice_controller" {
  policy_arn = aws_iam_policy.vpc_lattice_controller.arn
  role       = aws_iam_role.vpc_lattice_controller.name
}

resource "aws_iam_policy" "vpc_lattice_controller" {
  name        = "VPCLatticeControllerIAMPolicy"
  description = "IAM policy for VPCLatticeController"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "vpc-lattice:*",
          "eks:DescribeCluster",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroups",
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:DescribeLogGroups",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "tag:GetResources",
          "firehose:TagDeliveryStream",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
        ],
        Resource = "*",
      },
      {
        Effect   = "Allow",
        Action   = "iam:CreateServiceLinkedRole",
        Resource = "arn:aws:iam::*:role/aws-service-role/vpc-lattice.amazonaws.com/AWSServiceRoleForVpcLattice",
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = "vpc-lattice.amazonaws.com"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "iam:CreateServiceLinkedRole",
        Resource = "arn:aws:iam::*:role/aws-service-role/delivery.logs.amazonaws.com/AWSServiceRoleForLogDelivery",
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = "delivery.logs.amazonaws.com"
          }
        }
      },
    ],
  })
}

