locals {
  enabled           = module.this.enabled
  legacy_config_key = "_top_level"
  output_as_map     = local.enabled && length(var.config_map) > 0

  datadog_synthetics_private_location_id = module.datadog_synthetics_private_location.outputs.synthetics_private_location_id

  configs = local.enabled ? merge(var.config_map, length(var.synthetics_paths) == 0 ? {} : { (local.legacy_config_key) = {
    synthetics_paths = var.synthetics_paths
    # We do not need to include the top-level parameters here because they are always included,
    # but we do need to include the attributes to ensure they are always present, even when var.config_map is empty.
    config_parameters    = {}
    locations            = []
    tags                 = {}
    context_tags_enabled = null
  } }) : {}

  test_keys_list = flatten([for k, v in local.configs : [for kk, vv in module.datadog_synthetics_yaml_config[k].map_configs : {
    config_key = k
    test_key   = kk
  }]])

  # Convert list to map to avoid excessive changes when an item in the list is added or removed,
  # and to match merged maps back to the original config key.
  test_keys_map = { for v in local.test_keys_list : format("%s|%s", v.config_key, v.test_key) => v }

  tests_by_config = { for k, v in local.test_keys_map : v.config_key => {
    test_key  = v.test_key
    merge_key = k
  }... }

  synthetics_merged = { for k, v in local.configs : k => {
    for vv in local.tests_by_config[k] : vv.test_key => module.datadog_synthetics_merge[vv.merge_key].merged
  } }

  # Only return context tags that are specified
  context_tags = local.enabled ? {
    for k, v in module.this.tags :
    lower(k) => v
    if contains(var.context_tags, lower(k))
  } : {}
}

# We use a null resource to generate a helpful error message because we cannot
# put a precondition on a module.
resource "null_resource" "error_if_no_tests" {
  lifecycle {
    precondition {
      condition = length(compact([for k, v in module.datadog_synthetics_yaml_config : "empty" if length(v.map_configs) == 0])) == 0
      error_message = format(join("\n", [
        "No tests found for `config_map` keys:\n   %s",
        "Check that the `synthetic_paths` list matches at least one valid YAML file.\n\n   %s\n\n"
        ]), join("\n   ", [for k, v in module.datadog_synthetics_yaml_config : k if length(v.map_configs) == 0]),
        join("\n   ", concat(["<config_map key>: [<synthetics_paths>]", "--------------------------------------"],
          [for k, v in module.datadog_synthetics_yaml_config : format("%s: [\"%s\"]", k, join("\", \"", local.configs[k].synthetics_paths)) if length(v.map_configs) == 0])
      ))
    }
  }
}

moved {
  from = module.datadog_synthetics_yaml_config
  to   = module.datadog_synthetics_yaml_config["_top_level"]
}

moved {
  from = module.datadog_synthetics
  to   = module.datadog_synthetics["_top_level"]
}

# Convert all Datadog synthetics from YAML config to Terraform map
module "datadog_synthetics_yaml_config" {
  source  = "cloudposse/config/yaml"
  version = "1.0.2"

  for_each = local.configs

  map_config_local_base_path = path.module
  map_config_paths           = each.value.synthetics_paths

  # Give per-config parameters highest priority, then global, then context tags
  parameters = merge(var.config_parameters, each.value.config_parameters, local.context_tags)
  context    = module.this.context
}

module "datadog_synthetics_merge" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "1.0.2"

  for_each = local.test_keys_map

  # Merge in order: 1) datadog synthetics globals, context tags, config tags, configured test
  maps = [
    var.datadog_synthetics_globals,
    { tags = merge(
      coalesce(local.configs[each.value.config_key].context_tags_enabled, var.context_tags_enabled) ? local.context_tags : {},
    local.configs[each.value.config_key].tags) },
    module.datadog_synthetics_yaml_config[each.value.config_key].map_configs[each.value.test_key],
  ]
}

module "datadog_synthetics" {
  source  = "cloudposse/platform/datadog//modules/synthetics"
  version = "1.3.0"

  for_each = local.synthetics_merged

  # Disable default tags because we manage them ourselves in this module, because we want to make them lowercase.
  default_tags_enabled = false
  datadog_synthetics   = each.value

  locations = distinct(compact(concat(
    local.configs[each.key].locations,
    var.locations,
    [local.datadog_synthetics_private_location_id]
  )))

  alert_tags           = var.alert_tags
  alert_tags_separator = var.alert_tags_separator

  context = module.this.context
}
