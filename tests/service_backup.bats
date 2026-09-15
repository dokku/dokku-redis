#!/usr/bin/env bats
load test_helper

# Backups ship to an s3 bucket, so the tests need something that speaks s3.
# rustfs is a single container with no dependencies, which is enough for the
# plugin to authenticate against, push to, and be read back from.
RUSTFS_CONTAINER="dokku-test-rustfs"
RUSTFS_ACCESS_KEY="testaccesskey"
RUSTFS_SECRET_KEY="testsecretkey"
RUSTFS_BUCKET="dokku-test-backups"

rustfs_endpoint() {
  local ip
  ip="$(docker container inspect "$RUSTFS_CONTAINER" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')"
  echo "http://${ip}:9000"
}

aws_cli() {
  docker run --rm \
    --env "AWS_ACCESS_KEY_ID=$RUSTFS_ACCESS_KEY" \
    --env "AWS_SECRET_ACCESS_KEY=$RUSTFS_SECRET_KEY" \
    --env "AWS_DEFAULT_REGION=us-east-1" \
    amazon/aws-cli:latest --endpoint-url "$(rustfs_endpoint)" "$@"
}

start_rustfs() {
  docker container rm -f "$RUSTFS_CONTAINER" >/dev/null 2>&1 || true
  docker container run -d --name "$RUSTFS_CONTAINER" \
    --env "RUSTFS_ACCESS_KEY=$RUSTFS_ACCESS_KEY" \
    --env "RUSTFS_SECRET_KEY=$RUSTFS_SECRET_KEY" \
    rustfs/rustfs:latest >/dev/null

  # an unauthenticated request answers 403 once the api is listening, which is
  # the cheapest signal that it is up
  local waited=0
  until [[ "$(curl -s -o /dev/null -w '%{http_code}' "$(rustfs_endpoint)/" 2>/dev/null)" == "403" ]]; do
    waited=$((waited + 1))
    if [[ "$waited" -ge 30 ]]; then
      echo "rustfs did not become ready" >&2
      docker container logs "$RUSTFS_CONTAINER" >&2
      return 1
    fi
    sleep 1
  done

  aws_cli s3 mb "s3://$RUSTFS_BUCKET" >/dev/null
}

stop_rustfs() {
  docker container rm -f "$RUSTFS_CONTAINER" >/dev/null 2>&1 || true
}

setup() {
  dokku "$PLUGIN_COMMAND_PREFIX:create" ls
  start_rustfs
}

teardown() {
  # one test destroys the service itself, so this has to tolerate its absence
  dokku "$PLUGIN_COMMAND_PREFIX:destroy" ls -f || true
  stop_rustfs
}

authenticate() {
  dokku "$PLUGIN_COMMAND_PREFIX:backup-auth" ls "$RUSTFS_ACCESS_KEY" "$RUSTFS_SECRET_KEY" us-east-1 s3v4 "$(rustfs_endpoint)"
}

@test "($PLUGIN_COMMAND_PREFIX:backup) error when the service is not authenticated" {
  run dokku "$PLUGIN_COMMAND_PREFIX:backup" ls "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_failure
  assert_contains "${lines[*]}" "Missing AWS_ACCESS_KEY_ID file"
}

@test "($PLUGIN_COMMAND_PREFIX:backup) error when no bucket is given" {
  authenticate
  run dokku "$PLUGIN_COMMAND_PREFIX:backup" ls
  echo "output: $output"
  echo "status: $status"
  assert_failure
  assert_contains "${lines[*]}" "Please specify an aws bucket for the backup"
}

@test "($PLUGIN_COMMAND_PREFIX:backup) uploads to the bucket" {
  authenticate

  run dokku "$PLUGIN_COMMAND_PREFIX:backup" ls "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_success

  # the object is named for the datastore and the service, with a timestamp
  run aws_cli s3 ls "s3://$RUSTFS_BUCKET/" --recursive
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_contains "${lines[*]}" "$PLUGIN_COMMAND_PREFIX-ls-"
  assert_contains "${lines[*]}" ".tgz"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-deauth) stops the service backing up" {
  authenticate

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-deauth" ls
  echo "output: $output"
  echo "status: $status"
  assert_success

  run dokku "$PLUGIN_COMMAND_PREFIX:backup" ls "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_failure
  assert_contains "${lines[*]}" "Missing AWS_ACCESS_KEY_ID file"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-schedule) writes a cron file the dokku user cannot write directly" {
  authenticate

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_success

  # the cron directory belongs to root, so getting a file into it proves the
  # sudo grant the plugin installs is both valid and sufficient
  assert_exists "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls"

  run stat -c '%U %G %a' "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls"
  echo "output: $output"
  assert_success
  assert_output "root root 644"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-schedule) leaves no staged file behind" {
  authenticate

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_success

  # the entry is staged before a root owned helper moves it into place. It is
  # staged inside the service, because the directory beside it is the one the
  # listing enumerates to find services.
  assert_not_exists "$PLUGIN_DATA_ROOT/ls/.TMP_CRON_FILE"
  assert_not_exists "$PLUGIN_DATA_ROOT/.TMP_CRON_FILE"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-schedule-cat) prints the scheduled entry" {
  authenticate
  dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule-cat" ls
  echo "output: $output"
  echo "status: $status"
  assert_success
  assert_contains "${lines[*]}" "0 3 * * *"
  assert_contains "${lines[*]}" "$PLUGIN_COMMAND_PREFIX:backup ls $RUSTFS_BUCKET"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-schedule-cat) error when nothing is scheduled" {
  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule-cat" ls
  echo "output: $output"
  echo "status: $status"
  assert_failure
  assert_contains "${lines[*]}" "There is no scheduled backup for ls."
}

@test "($PLUGIN_COMMAND_PREFIX:backup-schedule) replaces an existing schedule" {
  authenticate
  dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "30 4 * * *" "$RUSTFS_BUCKET"
  echo "output: $output"
  echo "status: $status"
  assert_success

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule-cat" ls
  echo "output: $output"
  assert_success
  assert_contains "${lines[*]}" "30 4 * * *"
  assert_not_contains "${lines[*]}" "0 3 * * *"
}

@test "($PLUGIN_COMMAND_PREFIX:backup-unschedule) removes the cron file" {
  authenticate
  dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"
  assert_exists "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls"

  run dokku "$PLUGIN_COMMAND_PREFIX:backup-unschedule" ls
  echo "output: $output"
  echo "status: $status"
  assert_success

  if [[ -f "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls" ]]; then
    flunk "expected the cron file to be removed"
  fi
}

@test "($PLUGIN_COMMAND_PREFIX:destroy) removes the backup schedule with the service" {
  authenticate
  dokku "$PLUGIN_COMMAND_PREFIX:backup-schedule" ls "0 3 * * *" "$RUSTFS_BUCKET"
  assert_exists "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls"

  dokku "$PLUGIN_COMMAND_PREFIX:destroy" ls -f

  if [[ -f "/etc/cron.d/dokku-$PLUGIN_COMMAND_PREFIX-ls" ]]; then
    flunk "expected destroying the service to remove its cron file"
  fi
}
