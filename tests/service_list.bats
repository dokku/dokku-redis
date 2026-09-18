#!/usr/bin/env bats
load test_helper

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" l
}

teardown() {
  dokku "$PLUGIN_COMMAND_PREFIX:destroy" l -f
  sudo rm -f "$PLUGIN_DATA_ROOT/.TMP_CRON_FILE"
}

@test "($PLUGIN_COMMAND_PREFIX:list) with no exposed ports, no linked apps" {
  run dokku "$PLUGIN_COMMAND_PREFIX:list" --quiet
  assert_output "l"
}

@test "($PLUGIN_COMMAND_PREFIX:list) when there are no services" {
  dokku "$PLUGIN_COMMAND_PREFIX:destroy" l -f
  run dokku "$PLUGIN_COMMAND_PREFIX:list"
  assert_output "${lines[*]}" "There are no $PLUGIN_SERVICE services"
  dokku "$PLUGIN_COMMAND_PREFIX:create" l
}

@test "($PLUGIN_COMMAND_PREFIX:list) ignores a stray file among the services" {
  # the directory holding the services is what is enumerated to list them, so a
  # file left there by an interrupted operation was reported as a service of
  # its own
  sudo touch "$PLUGIN_DATA_ROOT/.TMP_CRON_FILE"

  run dokku "$PLUGIN_COMMAND_PREFIX:list" --quiet
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_output "l"
}
