#!/usr/bin/env bats

load test_helper

@test "(service) dokku" {
  dokku $SERVICE:create l
  assert_success

  dokku $SERVICE:info l
  assert_success

  dokku $SERVICE:stop l
  assert_success

  dokku $SERVICE:stop l
  assert_success

  dokku $SERVICE:expose l
  assert_success

  dokku $SERVICE:restart l
  assert_success

  dokku $SERVICE:info l
  assert_success

  dokku --force $SERVICE:destroy l
  assert_success
}
