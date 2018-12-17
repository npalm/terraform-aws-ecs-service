variable "vpc_id" {
  description = "ID of the VPC."
  type        = "string"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = "string"
}

variable "environment" {
  description = "Logical name of the environment, will be used as prefix and in tags."
  type        = "string"
}

variable "lb_subnetids" {
  description = "List of subnets to which the load balancer needs to be attached. Mandatory when enable_lb = true."
  type        = "list"
  default     = []
}

variable "task_role_arn" {
  description = "The AWS IAM role that will be provided to the task to perform AWS actions."
  type        = "string"
  default     = ""
}

variable "ecs_cluster_id" {
  description = "The id of the ECS cluster"
  type        = "string"
}

variable "task_network_mode" {
  description = "The network mode to be used in the task definiton. Supported modes are awsvpc and bridge."
  default     = "awsvpc"
}

variable "service_name" {
  description = "Logical name of the service."
  type        = "string"
}

variable "lb_target_group" {
  description = "The target group to connectect the container to the load balancer listerner."
  type        = "map"

  default = {
    container_port       = 8080
    host_port            = 80
    protocol             = "http"
    deregistration_delay = 300
  }
}

variable "lb_listener" {
  description = "The listner for the load balancer, SSL in only applied once a certificate arn is provided."
  type        = "map"

  default = {
    port            = "80"
    certificate_arn = ""
    ssl_policy      = "ELBSecurityPolicy-TLS-1-1-2017-01"
  }
}

variable "awsvpc_service_security_groups" {
  description = "List of security groups to be attached to service running in awsvpc network mode."
  default     = []
}

variable "awsvpc_service_subnetids" {
  description = "List of subnet ids to which a service is deployed in fargate mode."
  default     = []
}

variable "lb_internal" {
  description = "Indicates if the load balancer should be internal or external."
  default     = "true"
}

variable "task_definition" {
  description = "The AWS task definition of the containers to be created."
  type        = "string"
}

variable "service_desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = "1"
}

variable "lb_health_check" {
  description = "A health check block for the load balancer, see https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateTargetGroup.html more for details."
  type        = "list"
  default     = [{}]
}

variable "awsvpc_task_execution_role_arn" {
  description = "The role arn used for task execution. Required for network mode awsvpc."
  type        = "string"
  default     = ""
}

variable "service_launch_type" {
  description = "The launch type, can be EC2 or FARGATE."
  type        = "string"
  default     = "EC2"
}

variable "task_cpu" {
  description = "CPU value for the task, required for FARGATE."
  type        = "string"
  default     = ""
}

variable "task_memory" {
  description = "Memory value for the task, required for FARGATE."
  type        = "string"
  default     = ""
}

variable "enable_lb" {
  description = "Enable or disable the load balancer."
  default     = true
}

variable "ecs_service_role" {
  default = ""
}

variable "public_alb_whitelist" {
  type        = "list"
  description = "Enables to limit the ips that can access the  ALB over public network"
  default     = ["0.0.0.0/0"]
}
