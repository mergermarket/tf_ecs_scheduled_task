resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-schedule"
  description = "Schedule ECS target"

  schedule_expression = "${var.schedule_expression})"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  current = true
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "run-ecs-task"
  role = "${aws_iam_role.cloudwatch.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": [
            "ecs:RunTask"
        ],
        "Resource": [
            "${module.taskdef.arn}"
        ],
        "Condition": {
            "ArnLike": {
                "ecs:cluster": "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/default"
            }
        }
    }]
}
EOF
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-cloudwatch-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "target" {
  rule     = "${aws_cloudwatch_event_rule.schedule.name}"
  arn      = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/default"
  role_arn = "${aws_iam_role.cloudwatch.arn}"

  ecs_target {
    task_definition_arn = "${module.taskdef.arn}"
    task_count          = 1
  }
}

module "taskdef" {
  source = "github.com/mergermarket/tf_ecs_task_definition_with_task_role"

  family                = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}"
  container_definitions = ["${module.service_container_definition.rendered}"]
  policy                = "${var.task_role_policy}"
}

module "service_container_definition" {
  source = "github.com/mergermarket/tf_ecs_container_definition"

  name  = "${lookup(var.release, "component")}${var.name_suffix}"
  image = "${lookup(var.release, "image_id")}"

  container_env = "${merge(
    map(
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDOUT", "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stdout",
      "LOGSPOUT_CLOUDWATCHLOGS_LOG_GROUP_STDERR", "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stderr",
      "STATSD_HOST", "172.17.42.1",
      "STATSD_PORT", "8125",
      "STATSD_ENABLED", "true",
      "ENV_NAME", "${var.env}",
      "COMPONENT_NAME",  "${lookup(var.release, "component")}",
      "VERSION",  "${lookup(var.release, "version")}"
    ),
    var.common_application_environment,
    var.application_environment,
    var.secrets
  )}"

  labels {
    component          = "${lookup(var.release, "component")}"
    env                = "${var.env}"
    team               = "${lookup(var.release, "team")}"
    version            = "${lookup(var.release, "version")}"
    "logentries.token" = "${var.logentries_token}"
  }
}

resource "aws_cloudwatch_log_group" "stdout" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stdout"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_group" "stderr" {
  name              = "${var.env}-${lookup(var.release, "component")}${var.name_suffix}-stderr"
  retention_in_days = "7"
}
