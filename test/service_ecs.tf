locals {
  ecs_container_name = "blog"
  ecs_container_port = "80"
}

data "template_file" "blog_ecs" {
  template = "${file("${path.root}/task-definition/blog.json")}"

  vars {
    container_name   = "${local.ecs_container_name}"
    container_port   = "${local.ecs_container_port}"
    log_group_name   = "${aws_cloudwatch_log_group.log_group.name}"
    log_group_region = "${var.aws_region}"
    log_group_prefix = "blog-040"
  }
}

module "blog-ecs" {
  source = ".."

  service_name          = "blog-040-ecs"
  service_desired_count = 1

  environment = "${var.environment}"

  vpc_id       = "${module.vpc.vpc_id}"
  vpc_cidr     = "${module.vpc.vpc_cidr}"
  lb_subnetids = "${module.vpc.public_subnets}"

  ecs_cluster_id = "${aws_ecs_cluster.cluster.id}"

  lb_internal = false

  task_definition = "${data.template_file.blog_ecs.rendered}"
  task_cpu        = "256"
  task_memory     = "512"

  service_launch_type = "EC2"

  awsvpc_task_execution_role_arn = "${aws_iam_role.ecs_tasks_execution_role.arn}"
  awsvpc_service_security_groups = ["${aws_security_group.awsvpc_sg.id}"]
  awsvpc_service_subnetids       = "${module.vpc.private_subnets}"

  lb_target_group = {
    container_name = "${local.ecs_container_name}"
    container_port = "${local.ecs_container_port}"
  }

  lb_listener = {
    port     = 80
    protocol = "HTTP"
  }
}
