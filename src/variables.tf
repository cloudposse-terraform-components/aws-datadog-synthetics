variable "region" {
  type        = string
  description = "AWS Region"
}

variable "config_map" {
  type = map(object({
    synthetics_paths     = list(string)
    config_parameters    = optional(map(string), {})
    locations            = optional(list(string), [])
    tags                 = optional(map(string), {})
    context_tags_enabled = optional(bool, null) # if null, will use the value of the context_tags_enabled variable
  }))
  description = "Map of Datadog configuration values. Items in the objects are merged with the corresponding top-level variables."
  default     = {}
  nullable    = false
}


variable "synthetics_paths" {
  type        = list(string)
  description = "(Deprecated) List of paths to Datadog synthetic test configurations, repeated for all configs"
  default     = []
  nullable    = false
}

variable "alert_tags" {
  type        = list(string)
  description = "List of alert tags to add to all alert messages, e.g. `[\"@opsgenie\"]` or `[\"@devops\", \"@opsgenie\"]`"
  default     = null
}

variable "alert_tags_separator" {
  type        = string
  description = "Separator for the alert tags. All strings from the `alert_tags` variable will be joined into one string using the separator and then added to the alert message"
  default     = "\n"
  nullable    = false
}

variable "context_tags_enabled" {
  type        = bool
  description = "Whether to add context tags to add to each synthetic check. Can be overridden by `config_map.context_tags_enabled`."
  default     = true
  nullable    = false
}

variable "context_tags" {
  type        = set(string)
  description = "List of context tags to add to each synthetic check"
  default     = ["namespace", "tenant", "environment", "stage"]
  nullable    = false
}

variable "config_parameters" {
  type        = map(string)
  description = "Map of parameter values to interpolate into all Datadog Synthetic configurations"
  default     = {}
  nullable    = false
}

variable "datadog_synthetics_globals" {
  type        = any
  description = "Partial test configurations to use as defaults for every test"
  default     = {}
  nullable    = false
}

variable "locations" {
  type        = list(string)
  description = "Array of locations used to run every synthetic tests"
  default     = []
  nullable    = false
}

variable "private_location_test_enabled" {
  type        = bool
  description = <<-EOT
    Run test from private location created by the component indicated by `synthetics_private_location_component_name`,
    in addition to any locations specified by `locations` variable and `config_map.locations` value.
    Note that you can explicitly add private locations to the `locations` variable and `config_map.locations` value
    if you know the value; this is just a convenience for looking up the value from the component.
    EOT
  default     = false
  nullable    = false
}

variable "synthetics_private_location_component_name" {
  type        = string
  description = "The name of the Datadog synthetics private location component"
  default     = null
}
