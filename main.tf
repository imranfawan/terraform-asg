

resource "aws_autoscaling_lifecycle_hook" "instance_down_notify" {
  name                    = "instance-down"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  default_result          = "CONTINUE"
  heartbeat_timeout       = 31
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_metadata   = <<EOF
    {
    "instance_message": "Instance going down."
    }
    EOF
  notification_target_arn = var.notification_target_arn
  role_arn                = var.role_arn
}


resource "aws_autoscaling_lifecycle_hook" "instance_up_notify" {
  name                    = "instance-up"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  default_result          = "CONTINUE"
  heartbeat_timeout       = 31
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
  notification_metadata   = <<EOF
    {
    "instance_message": "Instance coming up."
    }
    EOF
  notification_target_arn = var.notification_target_arn
  role_arn                = var.role_arn
}


resource "aws_launch_configuration" "alc" {
  name_prefix = var.node_name_prefix

  image_id      = var.image_id
  instance_type = "t2.micro"
  key_name      = var.key_name

  security_groups             = ["${aws_security_group.allow_http.id}"]
  associate_public_ip_address = true

  user_data = <<USER_DATA
    #!/bin/bash
    yum update
    yum -y install nginx
    echo "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)" > /usr/share/nginx/html/index.html
    chkconfig nginx on
    service nginx start
    USER_DATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound connections and inbound ssh connection from configurable IP"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = formatlist("%s/32", var.ssh_source_ip)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_autoscaling_group" "asg" {
  name = "${aws_launch_configuration.alc.name}-asg"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  launch_configuration = aws_launch_configuration.alc.name
  availability_zones   = var.availability_zones

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = var.vpc_zone_identifier


  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "asg-demo"
    propagate_at_launch = true
  }
}