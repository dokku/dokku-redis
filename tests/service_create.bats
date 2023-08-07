#!/usr/bin/env bats
load test_helper

@test "($PLUGIN_COMMAND_PREFIX:create) success" {
  run dokku "$PLUGIN_COMMAND_PREFIX:create" l
  assert_contains "${lines[*]}" "container created: l"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l
}

@test "($PLUGIN_COMMAND_PREFIX:create) service with dashes" {
  run dokku "$PLUGIN_COMMAND_PREFIX:create" service-with-dashes
  assert_contains "${lines[*]}" "container created: service-with-dashes"
  assert_contains "${lines[*]}" "dokku-$PLUGIN_COMMAND_PREFIX-service-with-dashes"

  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" service-with-dashes
}

@test "($PLUGIN_COMMAND_PREFIX:create) service with redisgears image" {
  export PLUGIN_IMAGE="redislabs/redisgears"
  export PLUGIN_IMAGE_VERSION="1.2.5"
  run dokku "$PLUGIN_COMMAND_PREFIX:create" service-with-redisgears
  assert_contains "${lines[*]}" "container created: service-with-redisgears"
  assert_contains "${lines[*]}" "dokku-$PLUGIN_COMMAND_PREFIX-service-with-redisgears"

  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" service-with-redisgears
}

@test "($PLUGIN_COMMAND_PREFIX:create) service with redis-stack image" {
  export PLUGIN_IMAGE="redis/redis-stack"
  export PLUGIN_IMAGE_VERSION="6.2.6-v9"
  run dokku "$PLUGIN_COMMAND_PREFIX:create" service-with-redis-stack
  assert_contains "${lines[*]}" "container created: service-with-redis-stack"
  assert_contains "${lines[*]}" "dokku-$PLUGIN_COMMAND_PREFIX-service-with-redis-stack"

  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" service-with-redis-stack
}

@test "($PLUGIN_COMMAND_PREFIX:create) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:create"
  assert_contains "${lines[*]}" "Please specify a valid name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:create) error when there is an invalid name specified" {
  run dokku "$PLUGIN_COMMAND_PREFIX:create" d.erp
  assert_failure
}
