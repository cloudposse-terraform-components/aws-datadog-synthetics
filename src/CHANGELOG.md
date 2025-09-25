## Change > v2.0.0

### `config_map` added, old configuration moved

The `config_map` argument of the `datadog_synthetics_test` resource is now the primary way
to configure a test. The old collection of top-level arguments is still supported,
but it is now deprecated. The top level arguments are still applied to all tests, but
now you can deploy the same test multiple times with different parameters.

Note that if an entry in `config_map.synthetics_paths` specifies multiple test files, or if the test file
itself contains multiple tests, they will all get the same configuration. If you want
to deploy tests with different configurations, you will need to use multiple files and
configure them individually.

### Outputs are now maps

Corresponding to the change in the `config_map` argument, the outputs of the module
are all maps, with keys corresponding to the keys in the `config_map` argument.
The outputs relating to the top-level arguments are included in the maps
under the key `_top_level`.

### `config_paramters` now map of strings

The `config_parameters` argument of the `datadog_synthetics_test` resource is now a map of strings
instead of a `map(any)`. The values have to be converted to strings anyway to be interpolated
into the test configuration, and it resolves some type conversion issues in Terraform to
use fully-specified types.


## Changes v1.330.0

### API Schema accepted

Test can now be defined using the Datadog API schema, meaning that the test definition
returned by
- `https://api.datadoghq.com/api/v1/synthetics/tests/api/{public_id}`
- `https://api.datadoghq.com/api/v1/synthetics/tests/browser/{public_id}`

can be directly used a map value (you still need to supply a key, though).

You can mix tests using the API schema with tests using the old Terraform schema.
You could probably get away with mixing them in the same test, but it is not recommended.

### Default locations

Previously, the default locations for Synthetics tests were "all" public locations.
Now the default is no locations, in favor of locations being specified in each test configuration,
which is more flexible. Also, since the tests are expensive, it is better to err on the side of
too few test locations than too many.

