# AWS Terraform module to create Fargate / ECS service

This modules creates a Fargate or ECS service optionally with a application load balancer.
- Supports network modes: "awsvpc" and "bridge"
- Supports ECS and FARGATE
- Optionally a ALB can be created. (HTTP or HTTPS)



## Example usages:
Below an example for deloy a service to Fargate. See the test directroy for more and complete examples.

All variables prefix with:
- `awsvpc` : should only be required in case of network mode awsvpc (FARGATE as well).
- `lb` : should only be required in case enable_lb is set to true.

```
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

locals {
  container_name = "blog"
  container_port = "80"
}

data "template_file" "blog" {
  template = <<EOF
  [
    {
      "essential": true,
      "memoryReservation": null,
      "image": "npalm/040code.github.io:latest",
      "name": "${container_name}",
      "portMappings": [
        {
          "hostPort": ${container_port},
          "protocol": "tcp",
          "containerPort": ${container_port}
        }
      ],
      "environment": [],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${log_group_name}",
          "awslogs-region": "${log_group_region}",
          "awslogs-stream-prefix": "${log_group_prefix}"
        }
      }
    }
  ]

  EOF
  vars {
    container_name   = "${local.container_name}"
    container_port   = "${local.container_port}"
    log_group_name   = "${aws_cloudwatch_log_group.log_group.name}"
    log_group_region = "${var.aws_region}"
    log_group_prefix = "blog-040"
  }
}

module "blog" {
  source  = "npalm/ecs-service/aws"

  service_name          = "blog-040"
  service_desired_count = 1

  environment = "${var.environment}"

  vpc_id       = "${module.vpc.vpc_id}"
  vpc_cidr     = "${module.vpc.vpc_cidr}"
  lb_subnetids = "${module.vpc.public_subnets}"

  ecs_cluster_id = "${aws_ecs_cluster.cluster.id}"

  lb_internal = false

  task_definition = "${data.template_file.blog.rendered}"
  task_cpu        = "256"
  task_memory     = "512"

  service_launch_type = "FARGATE"

  awsvpc_task_execution_role_arn = "${aws_iam_role.ecs_tasks_execution_role.arn}"
  awsvpc_service_security_groups = ["${aws_security_group.awsvpc_sg.id}"]
  awsvpc_service_subnetids       = "${module.vpc.private_subnets}"

  lb_target_group = {
    container_name = "${local.container_name}"
    container_port = "${local.container_port}"
  }

  lb_listener = {
    port     = 80
    protocol = "HTTP"
  }
}


```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| awsvpc_service_security_groups | List of security groups to be attached to service running in awsvpc network mode. | string | `<list>` | no |
| awsvpc_service_subnetids | List of subnet ids to which a service is deployed in fargate mode. | string | `<list>` | no |
| awsvpc_task_execution_role_arn | The role arn used for task execution. Required for network mode awsvpc. | string | `` | no |
| ecs_cluster_id | The id of the ECS cluster | string | - | yes |
| ecs_service_role |  | string | `` | no |
| enable_alb | Enable or disable the load balancer. | string | `true` | no |
| environment | Logical name of the environment, will be used as prefix and in tags. | string | - | yes |
| lb_health_check | A health check block for the load balancer, see https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateTargetGroup.html more for details. | list | `<list>` | no |
| lb_internal | Indicates if the load balancer should be internal or external. | string | `true` | no |
| lb_listener | The listner for the load balancer, SSL in only applied once a certificate arn is provided. | map | `<map>` | no |
| lb_subnetids | List of subnets to which the load balancer needs to be attached. Mandatory when enable_alb = true. | list | `<list>` | no |
| lb_target_group | The target group to connectect the container to the load balancer listerner. | map | `<map>` | no |
| service_desired_count | The number of instances of the task definition to place and keep running. | string | `1` | no |
| service_launch_type | The launch type, can be EC2 or FARGATE. | string | `EC2` | no |
| service_name | Logical name of the service. | string | - | yes |
| task_cpu | CPU value for the task, required for FARGATE. | string | `` | no |
| task_definition | The AWS task definition of the containers to be created. | string | - | yes |
| task_memory | Memory value for the task, required for FARGATE. | string | `` | no |
| task_network_mode | The network mode to be used in the task definiton. Supported modes are awsvpc and bridge. | string | `awsvpc` | no |
| task_role_arn | The AWS IAM role that will be provided to the task to perform AWS actions. | string | `` | no |
| vpc_cidr | CIDR for the VPC. | string | - | yes |
| vpc_id | ID of the VPC. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_url | Service urls. |
| lb_dns_name | Load Balancer DNS Name. |
| task_definition_arn | Task definition ARN. |
| lb_target_group_arn | Load Balancer Target Group ARN. |
| lb_arn | Load Balancer ARN. |
| lb_listener_arn | Load Balancer Listener ARN. |
