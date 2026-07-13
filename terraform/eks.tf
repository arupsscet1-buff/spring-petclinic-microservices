module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~>21.0"

    name = "my-eks"
    kubernetes_version = "1.32"
    endpoint_public_access = true
    endpoint_private_access = true

    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets
    enable_cluster_creator_admin_permissions = true
    security_group_additional_rules = {
        jenkins_https = {
        description              = "Allow Jenkins EC2 to access EKS API"
        protocol                 = "tcp"
        from_port                = 443
        to_port                  = 443
        type                     = "ingress"
        source_security_group_id = aws_security_group.jenkins_sg.id
        }
    }

    addons = {
        eks-pod-identity-agent = {
            most_recent = true
        }
        coredns = {
            most_recent = true
        }
        kube-proxy = {
            most_recent = true
        }
        vpc-cni = {
            most_recent = true
            before_compute = true
        }
        aws-ebs-csi-driver = {
            most_recent = true
            pod_identity_association = [
                {
                role_arn        = aws_iam_role.ebs_csi.arn
                service_account = "ebs-csi-controller-sa"
                }
            ]
        }
    }

    #Node group for Spinnaker
    eks_managed_node_groups = {
        spinnaker = {
            labels = {
                role = "spinnaker"
            }

            instance_types = ["t3.large"]
            min_size = 1
            max_size = 4
            desired_size = 4

            tags = { "k8s.io/cluster-autoscaler/spinnaker" = "owned" }
        }
#Spot node groups
        apps = {
            labels = {
                role = "apps"
            }
            instance_types = ["t3.large","t3a.large", "m5.large", "m5a.large"]
            capacity_type = "SPOT"
            min_size = 1
            max_size = 2
            desired_size = 1

            taints = {
                dedicated = {
                    key = "dedicated"
                    value = "apps"
                    effect = "NO_SCHEDULE"
                }
            }

            tags = { "k8s.io/cluster-autoscaler/spot" = "owned" }

        }
    depends_on = module.vpc
    }
}

resource "time_sleep" "wait_for_cluster_access" {
  create_duration = "30s"
  depends_on      = [module.eks, module.vpc]
}



################################################################################
# EBS CSI Driver IAM Role + Pod Identity
################################################################################
resource "aws_iam_role" "ebs_csi" {
  name = "ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type = "gp3"
  }

  depends_on = [
    time_sleep.wait_for_cluster_access
  ]
}