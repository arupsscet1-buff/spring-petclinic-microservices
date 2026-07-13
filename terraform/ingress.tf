resource "helm_release" "alb_controller" {
    name       = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    namespace  = "kube-system"

    values = [
      yamlencode({
        clusterName = "my-eks"
        serviceAccount = {
          create = false
          name   = kubernetes_service_account.alb_controller.metadata[0].name
        }
        region = "ap-south-1"
        vpcId  = module.vpc.vpc_id
      })
    ]

    depends_on = [
        module.eks,
        time_sleep.wait_for_cluster_access,
        aws_iam_role_policy_attachment.alb_controller,
        # CRITICAL FIX: Ensure the association is built BEFORE Helm tries to use it
        aws_eks_pod_identity_association.alb_controller 
    ]
}

resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "alb-controller-role"

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

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    
    # The controller chart requires these labels on manual service accounts
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }
  depends_on = [time_sleep.wait_for_cluster_access]
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = kubernetes_service_account.alb_controller.metadata[0].name
  role_arn        = aws_iam_role.alb_controller.arn

  depends_on = [time_sleep.wait_for_cluster_access]
}
