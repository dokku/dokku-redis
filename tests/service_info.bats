#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l >&2
}

teardown() {
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" l >&2
}

@test "($PLUGIN_COMMAND_PREFIX:info) error when there are no arguments" {
  run dokku "$PLUGIN_COMMAND_PREFIX:info"
  assert_contains "${lines[*]}" "Please specify a name for the service"
}

@test "($PLUGIN_COMMAND_PREFIX:info) error when service does not exist" {
  run dokku "$PLUGIN_COMMAND_PREFIX:info" not_existing_service
  assert_contains "${lines[*]}" "Redis service not_existing_service does not exist"
}

@test "($PLUGIN_COMMAND_PREFIX:info) success" {
  run dokku "$PLUGIN_COMMAND_PREFIX:info" l
  assert_contains "${lines[*]}" "DSN: redis://dokku-redis-l:6379"
}

@test "($PLUGIN_COMMAND_PREFIX:info) replaces underscores by dash in hostname" {
  dokku "$PLUGIN_COMMAND_PREFIX:create" test_with_underscores
  run dokku "$PLUGIN_COMMAND_PREFIX:info" test_with_underscores
  assert_contains "${lines[*]}" "DSN: redis://dokku-redis-test-with-underscores:6379"
  dokku --force "$PLUGIN_COMMAND_PREFIX:destroy" test_with_underscores
}
