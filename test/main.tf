provider "aws" {
  region  = "${var.aws_region}"
  version = "1.7.1"
}

module "vpc" {
  source  = "npalm/vpc/aws"
  version = "1.1.0"

  environment = "${var.environment}"
  aws_region  = "${var.aws_region}"

  create_private_hosted_zone = "false"

  availability_zones = {
    us-east-1 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.environment}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs-cluster"
}

resource "aws_security_group" "awsvpc_sg" {
  name   = "${var.environment}-awsvpc-cluster-sg"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 0
    to_port   = 65535

    cidr_blocks = [
      "${module.vpc.vpc_cidr}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "${var.environment}-ecs-cluster-sg"
    Environment = "${var.environment}"
  }
}
