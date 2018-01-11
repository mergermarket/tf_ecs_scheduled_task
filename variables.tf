variable "env" {
  description = "Environment name"
}

variable "schedule_expression" {
  description = "see https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
}

variable "platform_config" {
  description = "Platform configuration"
  type        = "map"
  default     = {}
}

variable "release" {
  type        = "map"
  description = "Metadata about the release"
}

variable "secrets" {
  type        = "map"
  description = "Secret credentials fetched using credstash"
  default     = {}
}

variable "name_suffix" {
  description = "Set a suffix that will be applied to the name in order that a component can have multiple services per environment"
  type        = "string"
  default     = ""
}

variable "logentries_token" {
  description = "The Logentries token used to be able to get logs sent to a specific log set."
  type        = "string"
  default     = ""
}

variable "task_role_policy" {
  description = "IAM policy document to apply to the tasks via a task role"
  type        = "string"

  default = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Deny",
      "Resource": "*"
    }
  ]
}
END
}

variable "common_application_environment" {
  description = "Environment parameters passed to the container for all environments"
  type        = "map"
  default     = {}
}

variable "application_environment" {
  description = "Environment specific parameters passed to the container"
  type        = "map"
  default     = {}
}
