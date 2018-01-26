resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("${var.ssh_key_file_ecs}")}"
}

module "ecs_instances" {
  source  = "npalm/ecs-instances/aws"
  version = "0.3.0"

  ecs_cluster_name = "${aws_ecs_cluster.cluster.name}"
  aws_region       = "${var.aws_region}"
  environment      = "${var.environment}"
  key_name         = "${var.key_name}"
  vpc_id           = "${module.vpc.vpc_id}"
  vpc_cidr         = "${module.vpc.vpc_cidr}"
  subnets          = "${module.vpc.private_subnets}"
}
