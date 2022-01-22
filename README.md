# dokku redis [![Build Status](https://img.shields.io/github/workflow/status/dokku/dokku-redis/CI/master?style=flat-square "Build Status")](https://github.com/dokku/dokku-redis/actions/workflows/ci.yml?query=branch%3Amaster) [![IRC Network](https://img.shields.io/badge/irc-libera-blue.svg?style=flat-square "IRC Libera")](https://webchat.libera.chat/?channels=dokku)

Official redis plugin for dokku. Currently defaults to installing [redis 6.2.6](https://hub.docker.com/_/redis/).

## Requirements

- dokku 0.19.x+
- docker 1.8.x

## Installation

```shell
# on 0.19.x+
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
```

## Commands

```
redis:app-links <app>                              # list all redis service links for a given app
redis:backup <service> <bucket-name> [--use-iam]   # create a backup of the redis service to an existing s3 bucket
redis:backup-auth <service> <aws-access-key-id> <aws-secret-access-key> <aws-default-region> <aws-signature-version> <endpoint-url> # set up authentication for backups on the redis service
redis:backup-deauth <service>                      # remove backup authentication for the redis service
redis:backup-schedule <service> <schedule> <bucket-name> [--use-iam] # schedule a backup of the redis service
redis:backup-schedule-cat <service>                # cat the contents of the configured backup cronfile for the service
redis:backup-set-encryption <service> <passphrase> # set encryption for all future backups of redis service
redis:backup-unschedule <service>                  # unschedule the backup of the redis service
redis:backup-unset-encryption <service>            # unset encryption for future backups of the redis service
redis:clone <service> <new-service> [--clone-flags...] # create container <new-name> then copy data from <name> into <new-name>
redis:connect <service>                            # connect to the service via the redis connection tool
redis:create <service> [--create-flags...]         # create a redis service
redis:destroy <service> [-f|--force]               # delete the redis service/data/container if there are no links left
redis:enter <service>                              # enter or run a command in a running redis service container
redis:exists <service>                             # check if the redis service exists
redis:export <service>                             # export a dump of the redis service database
redis:expose <service> <ports...>                  # expose a redis service on custom host:port if provided (random port on the 0.0.0.0 interface if otherwise unspecified)
redis:import <service>                             # import a dump into the redis service database
redis:info <service> [--single-info-flag]          # print the service information
redis:link <service> <app> [--link-flags...]       # link the redis service to the app
redis:linked <service> <app>                       # check if the redis service is linked to an app
redis:links <service>                              # list all apps linked to the redis service
redis:list                                         # list all redis services
redis:logs <service> [-t|--tail] <tail-num-optional> # print the most recent log(s) for this service
redis:promote <service> <app>                      # promote service <service> as REDIS_URL in <app>
redis:restart <service>                            # graceful shutdown and restart of the redis service container
redis:start <service>                              # start a previously stopped redis service
redis:stop <service>                               # stop a running redis service
redis:unexpose <service>                           # unexpose a previously exposed redis service
redis:unlink <service> <app>                       # unlink the redis service from the app
redis:upgrade <service> [--upgrade-flags...]       # upgrade service <service> to the specified versions
```

## Usage

Help for any commands can be displayed by specifying the command as an argument to redis:help. Plugin help output in conjunction with any files in the `docs/` folder is used to generate the plugin documentation. Please consult the `redis:help` command for any undocumented commands.

### Basic Usage

### create a redis service

```shell
# usage
dokku redis:create <service> [--create-flags...]
```

flags:

- `-c|--config-options "--args --go=here"`: extra arguments to pass to the container create command (default: `None`)
- `-C|--custom-env "USER=alpha;HOST=beta"`: semi-colon delimited environment variables to start the service with
- `-i|--image IMAGE`: the image name to start the service with
- `-I|--image-version IMAGE_VERSION`: the image version to start the service with
- `-m|--memory MEMORY`: container memory limit in megabytes (default: unlimited)
- `-p|--password PASSWORD`: override the user-level service password
- `-r|--root-password PASSWORD`: override the root-level service password
- `-s|--shm-size SHM_SIZE`: override shared memory size for redis docker container

Create a redis service named lollipop:

```shell
dokku redis:create lollipop
```

You can also specify the image and image version to use for the service. It *must* be compatible with the redis image.

```shell
export REDIS_IMAGE="redis"
export REDIS_IMAGE_VERSION="${PLUGIN_IMAGE_VERSION}"
dokku redis:create lollipop
```

You can also specify custom environment variables to start the redis service in semi-colon separated form.

```shell
export REDIS_CUSTOM_ENV="USER=alpha;HOST=beta"
dokku redis:create lollipop
```

### print the service information

```shell
# usage
dokku redis:info <service> [--single-info-flag]
```

flags:

- `--config-dir`: show the service configuration directory
- `--data-dir`: show the service data directory
- `--dsn`: show the service DSN
- `--exposed-ports`: show service exposed ports
- `--id`: show the service container id
- `--internal-ip`: show the service internal ip
- `--links`: show the service app links
- `--service-root`: show the service root directory
- `--status`: show the service running status
- `--version`: show the service image version

Get connection information as follows:

```shell
dokku redis:info lollipop
```

You can also retrieve a specific piece of service info via flags:

```shell
dokku redis:info lollipop --config-dir
dokku redis:info lollipop --data-dir
dokku redis:info lollipop --dsn
dokku redis:info lollipop --exposed-ports
dokku redis:info lollipop --id
dokku redis:info lollipop --internal-ip
dokku redis:info lollipop --links
dokku redis:info lollipop --service-root
dokku redis:info lollipop --status
dokku redis:info lollipop --version
```

### list all redis services

```shell
# usage
dokku redis:list 
```

List all services:

```shell
dokku redis:list
```

### print the most recent log(s) for this service

```shell
# usage
dokku redis:logs <service> [-t|--tail] <tail-num-optional>
```

flags:

- `-t|--tail [<tail-num>]`: do not stop when end of the logs are reached and wait for additional output

You can tail logs for a particular service:

```shell
dokku redis:logs lollipop
```

By default, logs will not be tailed, but you can do this with the --tail flag:

```shell
dokku redis:logs lollipop --tail
```

The default tail setting is to show all logs, but an initial count can also be specified:

```shell
dokku redis:logs lollipop --tail 5
```

### link the redis service to the app

```shell
# usage
dokku redis:link <service> <app> [--link-flags...]
```

flags:

- `-a|--alias "BLUE_DATABASE"`: an alternative alias to use for linking to an app via environment variable
- `-q|--querystring "pool=5"`: ampersand delimited querystring arguments to append to the service link

A redis service can be linked to a container. This will use native docker links via the docker-options plugin. Here we link it to our `playground` app.

> NOTE: this will restart your app

```shell
dokku redis:link lollipop playground
```

The following environment variables will be set automatically by docker (not on the app itself, so they won’t be listed when calling dokku config):

```
DOKKU_REDIS_LOLLIPOP_NAME=/lollipop/DATABASE
DOKKU_REDIS_LOLLIPOP_PORT=tcp://172.17.0.1:6379
DOKKU_REDIS_LOLLIPOP_PORT_6379_TCP=tcp://172.17.0.1:6379
DOKKU_REDIS_LOLLIPOP_PORT_6379_TCP_PROTO=tcp
DOKKU_REDIS_LOLLIPOP_PORT_6379_TCP_PORT=6379
DOKKU_REDIS_LOLLIPOP_PORT_6379_TCP_ADDR=172.17.0.1
```

The following will be set on the linked application by default:

```
REDIS_URL=redis://:SOME_PASSWORD@dokku-redis-lollipop:6379
```

The host exposed here only works internally in docker containers. If you want your container to be reachable from outside, you should use the `expose` subcommand. Another service can be linked to your app:

```shell
dokku redis:link other_service playground
```

It is possible to change the protocol for `REDIS_URL` by setting the environment variable `REDIS_DATABASE_SCHEME` on the app. Doing so will after linking will cause the plugin to think the service is not linked, and we advise you to unlink before proceeding.

```shell
dokku config:set playground REDIS_DATABASE_SCHEME=redis2
dokku redis:link lollipop playground
```

This will cause `REDIS_URL` to be set as:

```
redis2://:SOME_PASSWORD@dokku-redis-lollipop:6379
```

### unlink the redis service from the app

```shell
# usage
dokku redis:unlink <service> <app>
```

You can unlink a redis service:

> NOTE: this will restart your app and unset related environment variables

```shell
dokku redis:unlink lollipop playground
```

### Service Lifecycle

The lifecycle of each service can be managed through the following commands:

### connect to the service via the redis connection tool

```shell
# usage
dokku redis:connect <service>
```

Connect to the service via the redis connection tool:

> NOTE: disconnecting from ssh while running this command may leave zombie processes due to moby/moby#9098

```shell
dokku redis:connect lollipop
```

### enter or run a command in a running redis service container

```shell
# usage
dokku redis:enter <service>
```

A bash prompt can be opened against a running service. Filesystem changes will not be saved to disk.

> NOTE: disconnecting from ssh while running this command may leave zombie processes due to moby/moby#9098

```shell
dokku redis:enter lollipop
```

You may also run a command directly against the service. Filesystem changes will not be saved to disk.

```shell
dokku redis:enter lollipop touch /tmp/test
```

### expose a redis service on custom host:port if provided (random port on the 0.0.0.0 interface if otherwise unspecified)

```shell
# usage
dokku redis:expose <service> <ports...>
```

Expose the service on the service's normal ports, allowing access to it from the public interface (`0.0.0.0`):

```shell
dokku redis:expose lollipop 6379
```

Expose the service on the service's normal ports, with the first on a specified ip adddress (127.0.0.1):

```shell
dokku redis:expose lollipop 127.0.0.1:6379
```

### unexpose a previously exposed redis service

```shell
# usage
dokku redis:unexpose <service>
```

Unexpose the service, removing access to it from the public interface (`0.0.0.0`):

```shell
dokku redis:unexpose lollipop
```

### promote service <service> as REDIS_URL in <app>

```shell
# usage
dokku redis:promote <service> <app>
```

If you have a redis service linked to an app and try to link another redis service another link environment variable will be generated automatically:

```
DOKKU_REDIS_BLUE_URL=redis://:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
```

You can promote the new service to be the primary one:

> NOTE: this will restart your app

```shell
dokku redis:promote other_service playground
```

This will replace `REDIS_URL` with the url from other_service and generate another environment variable to hold the previous value if necessary. You could end up with the following for example:

```
REDIS_URL=redis://:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
DOKKU_REDIS_BLUE_URL=redis://:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
DOKKU_REDIS_SILVER_URL=redis://:SOME_PASSWORD@dokku-redis-lollipop:6379/lollipop
```

### start a previously stopped redis service

```shell
# usage
dokku redis:start <service>
```

Start the service:

```shell
dokku redis:start lollipop
```

### stop a running redis service

```shell
# usage
dokku redis:stop <service>
```

Stop the service and the running container:

```shell
dokku redis:stop lollipop
```

### graceful shutdown and restart of the redis service container

```shell
# usage
dokku redis:restart <service>
```

Restart the service:

```shell
dokku redis:restart lollipop
```

### upgrade service <service> to the specified versions

```shell
# usage
dokku redis:upgrade <service> [--upgrade-flags...]
```

flags:

- `-c|--config-options "--args --go=here"`: extra arguments to pass to the container create command (default: `None`)
- `-C|--custom-env "USER=alpha;HOST=beta"`: semi-colon delimited environment variables to start the service with
- `-i|--image IMAGE`: the image name to start the service with
- `-I|--image-version IMAGE_VERSION`: the image version to start the service with
- `-R|--restart-apps "true"`: whether to force an app restart
- `-s|--shm-size SHM_SIZE`: override shared memory size for redis docker container

You can upgrade an existing service to a new image or image-version:

```shell
dokku redis:upgrade lollipop
```

### Service Automation

Service scripting can be executed using the following commands:

### list all redis service links for a given app

```shell
# usage
dokku redis:app-links <app>
```

List all redis services that are linked to the `playground` app.

```shell
dokku redis:app-links playground
```

### create container <new-name> then copy data from <name> into <new-name>

```shell
# usage
dokku redis:clone <service> <new-service> [--clone-flags...]
```

flags:

- `-c|--config-options "--args --go=here"`: extra arguments to pass to the container create command (default: `None`)
- `-C|--custom-env "USER=alpha;HOST=beta"`: semi-colon delimited environment variables to start the service with
- `-i|--image IMAGE`: the image name to start the service with
- `-I|--image-version IMAGE_VERSION`: the image version to start the service with
- `-m|--memory MEMORY`: container memory limit in megabytes (default: unlimited)
- `-p|--password PASSWORD`: override the user-level service password
- `-r|--root-password PASSWORD`: override the root-level service password
- `-s|--shm-size SHM_SIZE`: override shared memory size for redis docker container

You can clone an existing service to a new one:

```shell
dokku redis:clone lollipop lollipop-2
```

### check if the redis service exists

```shell
# usage
dokku redis:exists <service>
```

Here we check if the lollipop redis service exists.

```shell
dokku redis:exists lollipop
```

### check if the redis service is linked to an app

```shell
# usage
dokku redis:linked <service> <app>
```

Here we check if the lollipop redis service is linked to the `playground` app.

```shell
dokku redis:linked lollipop playground
```

### list all apps linked to the redis service

```shell
# usage
dokku redis:links <service>
```

List all apps linked to the `lollipop` redis service.

```shell
dokku redis:links lollipop
```

### Data Management

The underlying service data can be imported and exported with the following commands:

### import a dump into the redis service database

```shell
# usage
dokku redis:import <service>
```

Import a datastore dump:

```shell
dokku redis:import lollipop < data.dump
```

### export a dump of the redis service database

```shell
# usage
dokku redis:export <service>
```

By default, datastore output is exported to stdout:

```shell
dokku redis:export lollipop
```

You can redirect this output to a file:

```shell
dokku redis:export lollipop > data.dump
```

### Backups

Datastore backups are supported via AWS S3 and S3 compatible services like [minio](https://github.com/minio/minio).

You may skip the `backup-auth` step if your dokku install is running within EC2 and has access to the bucket via an IAM profile. In that case, use the `--use-iam` option with the `backup` command.

Backups can be performed using the backup commands:

### set up authentication for backups on the redis service

```shell
# usage
dokku redis:backup-auth <service> <aws-access-key-id> <aws-secret-access-key> <aws-default-region> <aws-signature-version> <endpoint-url>
```

Setup s3 backup authentication:

```shell
dokku redis:backup-auth lollipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
```

Setup s3 backup authentication with different region:

```shell
dokku redis:backup-auth lollipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
```

Setup s3 backup authentication with different signature version and endpoint:

```shell
dokku redis:backup-auth lollipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_SIGNATURE_VERSION ENDPOINT_URL
```

More specific example for minio auth:

```shell
dokku redis:backup-auth lollipop MINIO_ACCESS_KEY_ID MINIO_SECRET_ACCESS_KEY us-east-1 s3v4 https://YOURMINIOSERVICE
```

### remove backup authentication for the redis service

```shell
# usage
dokku redis:backup-deauth <service>
```

Remove s3 authentication:

```shell
dokku redis:backup-deauth lollipop
```

### create a backup of the redis service to an existing s3 bucket

```shell
# usage
dokku redis:backup <service> <bucket-name> [--use-iam]
```

flags:

- `-u|--use-iam`: use the IAM profile associated with the current server

Backup the `lollipop` service to the `my-s3-bucket` bucket on `AWS`:`

```shell
dokku redis:backup lollipop my-s3-bucket --use-iam
```

Restore a backup file (assuming it was extracted via `tar -xf backup.tgz`):

```shell
dokku redis:import lollipop < backup-folder/export
```

### set encryption for all future backups of redis service

```shell
# usage
dokku redis:backup-set-encryption <service> <passphrase>
```

Set the GPG-compatible passphrase for encrypting backups for backups:

```shell
dokku redis:backup-set-encryption lollipop
```

### unset encryption for future backups of the redis service

```shell
# usage
dokku redis:backup-unset-encryption <service>
```

Unset the `GPG` encryption passphrase for backups:

```shell
dokku redis:backup-unset-encryption lollipop
```

### schedule a backup of the redis service

```shell
# usage
dokku redis:backup-schedule <service> <schedule> <bucket-name> [--use-iam]
```

flags:

- `-u|--use-iam`: use the IAM profile associated with the current server

Schedule a backup:

> 'schedule' is a crontab expression, eg. "0 3 * * *" for each day at 3am

```shell
dokku redis:backup-schedule lollipop "0 3 * * *" my-s3-bucket
```

Schedule a backup and authenticate via iam:

```shell
dokku redis:backup-schedule lollipop "0 3 * * *" my-s3-bucket --use-iam
```

### cat the contents of the configured backup cronfile for the service

```shell
# usage
dokku redis:backup-schedule-cat <service>
```

Cat the contents of the configured backup cronfile for the service:

```shell
dokku redis:backup-schedule-cat lollipop
```

### unschedule the backup of the redis service

```shell
# usage
dokku redis:backup-unschedule <service>
```

Remove the scheduled backup from cron:

```shell
dokku redis:backup-unschedule lollipop
```

### Disabling `docker pull` calls

If you wish to disable the `docker pull` calls that the plugin triggers, you may set the `REDIS_DISABLE_PULL` environment variable to `true`. Once disabled, you will need to pull the service image you wish to deploy as shown in the `stderr` output.

Please ensure the proper images are in place when `docker pull` is disabled.
