/*
 * Module: tf_aws_asg_elb
 *
 * This template creates the following resources
 *   - A launch configuration
 *   - A auto-scaling group
 *
 * It requires you create an ELB instance before you use it.
 */

data "template_file" "cloud-init" {
  template = "${file("${path.module}/cloud-init.yaml.tpl")}"
  count    = "${var.count}"
  vars {
    hostname = "${var.hostname}"
  }
}

data "template_cloudinit_config" "userdata" {
  gzip  = false
  count = "${var.count}"
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      =  "${element(data.template_file.cloud-init.*.rendered, count.index)}"
  }
}

resource "aws_launch_configuration" "launch_config" {
  name_prefix = "${var.lc_name}-"
  image_id = "${var.ami_id}"
  iam_instance_profile = "${var.iam_instance_profile}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  security_groups = ["${var.security_group}"]
  user_data = "${element(data.template_cloudinit_config.userdata.*.rendered, count.index)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main_asg" {
  # We want this to explicitly depend on the launch config above
  depends_on = ["aws_launch_configuration.launch_config"]

  name = "${var.asg_name}"

  # The chosen availability zones *must* match the AZs the VPC subnets are tied to.
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.vpc_zone_subnets)}"]

  # Uses the ID from the launch config created above
  launch_configuration = "${aws_launch_configuration.launch_config.id}"

  max_size = "${var.asg_number_of_instances}"
  min_size = "${var.asg_minimum_number_of_instances}"
  desired_capacity = "${var.asg_desired_number_of_instances}"

  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type = "${var.health_check_type}"

  load_balancers = ["${split(",", var.load_balancer_names)}"]

  target_group_arns = ["${split(",", var.target_group_arns)}"]

  lifecycle {
    create_before_destroy = true
  }

}
