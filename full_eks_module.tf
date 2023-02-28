# VPC module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = "amit-eks-vpc"

  cidr = "10.0.0.0/16" # Replace with your desired CIDR block

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"] # Replace with your desired AZs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] # Replace with your desired private subnets
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"] # Replace with your desired public subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# EKS module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_id
  cluster_version = "1.24"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


    # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t2.micro"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }
        override = [
          {
            instance_type     = "t2.medium"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t2.micro"
            weighted_capacity = "2"
          },
        ]
      }
    }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
}

# # ASG
# resource "aws_launch_configuration" "my_lc1" {
#   name_prefix = "my-lc"
#   image_id    = "ami-06d94a781b544c133"
#   instance_type = "t2.micro"

#   security_groups = [aws_security_group.my_sg.id]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "my_asg" {
#   name                 = "my-asg"
#   launch_configuration = aws_launch_configuration.my_lc1.name
#   min_size             = 2
#   max_size             = 2
#   desired_capacity     = 2
#   vpc_zone_identifier  = module.vpc.private_subnets

#   tag {
#     key                 = "Name"
#     value               = "my-asg"
#     propagate_at_launch = true
#   }
# }

# # SG
# resource "aws_security_group" "my_sg" {
#   name_prefix = "my-sg"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

# # EKS
# # IAM Role
# resource "aws_iam_role" "eks" {
#   name = "my-eks-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }
# # IAM Role Policy Attachment
# resource "aws_iam_role_policy_attachment" "eks" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks.name
# }

# # EKS Fargate Profile
# resource "aws_eks_fargate_profile" "eks_fargate" {
#   fargate_profile_name = "my-fargate-profile"
#   cluster_name         = module.eks.cluster_id

#   pod_execution_role_arn = aws_iam_role.eks.arn

#   subnet_ids = module.vpc.private_subnets


#   selector {
#     namespace = "default"
#     labels    = {
#       App = "my-app"
#     }
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.eks
#   ]
# }

# # Outputs
# output "asg_id" {
#   value = aws_autoscaling_group.my_asg.id
# }

# output "sg_id" {
#   value = aws_security_group.my_sg.id
# }

# output "lc1_id" {
#   value = aws_launch_configuration.my_lc1.id
# }