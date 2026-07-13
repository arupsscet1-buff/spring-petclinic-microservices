data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t3.large"
    subnet_id                   = module.vpc.public_subnets[0]
    key_name                    = "arupdops-mumbai"
    vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
    iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
    monitoring                  = true
    root_block_device {
        volume_size = 80
    }

    user_data = <<-EOF
        #!/bin/bash
        #Install Jenkins
        sudo apt update -y
        sudo apt install fontconfig openjdk-21-jre -y
        java -version

        sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
        sudo echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
        sudo apt update
        sudo apt install jenkins -y

        #Install kubectl and helm
        sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo chmod +x kubectl
        sudo mv kubectl /usr/local/bin/

        sudo curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

        #Install AWS CLI
        sudo apt update && sudo apt install -y unzip curl
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install

        EOF

    depends_on = [ module.vpc ]
    tags = {Name = "jenkins-server"}
}

resource "aws_security_group" "jenkins_sg" {
    name = "jenkins-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        description = "Allow jenkins"
        from_port = 8080
        to_port   = 8080
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "Allow ssh"
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# IAM role for Jenkins(ECR push + EKS access)
resource "aws_iam_role" "jenkins_role" {
    name = "jenkins-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
    })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
    role = aws_iam_role.jenkins_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
    role = aws_iam_role.jenkins_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
    name = "jenkins-profile"
    role = aws_iam_role.jenkins_role.name
}


resource "aws_eip" "jenkins" {
  domain = "vpc"
  tags   = { Name = "jenkins-controller-eip" }
}

resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}