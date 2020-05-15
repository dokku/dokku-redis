# dokku redis [![Build Status](https://img.shields.io/circleci/project/github/dokku/dokku-redis.svg?branch=master&style=flat-square "Build Status")](https://circleci.com/gh/dokku/dokku-redis/tree/master) [![IRC Network](https://img.shields.io/badge/irc-freenode-blue.svg?style=flat-square "IRC Freenode")](https://webchat.freenode.net/?channels=dokku)

Official redis plugin for dokku. Currently defaults to installing [redis 5.0.7](https://hub.docker.com/_/redis/).

## Requirements

- dokku 0.12.x+
- docker 1.8.x

## Installation

```shell
# on 0.12.x+
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
```

## Commands

```
redis:app-links <app>                              # list all redis service links for a given app
redis:backup <service> <bucket-name> [--use-iam]   # creates a backup of the redis service to an existing s3 bucket
redis:backup-auth <service> <aws-access-key-id> <aws-secret-access-key> <aws-default-region> <aws-signature-version> <endpoint-url> # sets up authentication for backups on the redis service
redis:backup-deauth <service>                      # removes backup authentication for the redis service
redis:backup-schedule <service> <schedule> <bucket-name> [--use-iam] # schedules a backup of the redis service
redis:backup-schedule-cat <service>                # cat the contents of the configured backup cronfile for the service
redis:backup-set-encryption <service> <passphrase> # sets encryption for all future backups of redis service
redis:backup-unschedule <service>                  # unschedules the backup of the redis service
redis:backup-unset-encryption <service>            # unsets encryption for future backups of the redis service
redis:clone <service> <new-service> [--clone-flags...] # create container <new-name> then copy data from <name> into <new-name>
redis:connect <service>                            # connect to the service via the redis connection tool
redis:create <service> [--create-flags...]         # create a redis service
redis:destroy <service> [-f|--force]               # delete the redis service/data/container if there are no links left
redis:enter <service>                              # enter or run a command in a running redis service container
redis:exists <service>                             # check if the redis service exists
redis:export <service>                             # export a dump of the redis service database
redis:expose <service> <ports...>                  # expose a redis service on custom port if provided (random port otherwise)
redis:import <service>                             # import a dump into the redis service database
redis:info <service> [--single-info-flag]          # print the service information
redis:link <service> <app> [--link-flags...]       # link the redis service to the app
redis:linked <service> <app>                       # check if the redis service is linked to an app
redis:links <service>                              # list all apps linked to the redis service
redis:list                                         # list all redis services
redis:logs <service> [-t|--tail]                   # print the most recent log(s) for this service
redis:promote <service> <app>                      # promote service <service> as REDIS_URL in <app>
redis:restart <service>                            # graceful shutdown and restart of the redis service container
redis:start <service>                              # start a previously stopped redis service
redis:stop <service>                               # stop a running redis service
redis:unexpose <service>                           # unexpose a previously exposed redis service
redis:unlink <service> <app>                       # unlink the redis service from the app
redis:upgrade <service> [--upgrade-flags...]       # upgrade service <service> to the specified versions
```

## Usage

Help for any commands can be displayed by specifying the command as an argument to redis:help. Please consult the `redis:help` command for any undocumented commands.

### Basic Usage

### create a redis service

```shell
# usage
dokku redis:create <service> [--create-flags...]
```

Create a redis service named lolipop:

```shell
dokku redis:create lolipop
```

You can also specify the image and image version to use for the service. It *must* be compatible with the ${plugin_image} image.

```shell
export REDIS_IMAGE="${PLUGIN_IMAGE}"
export REDIS_IMAGE_VERSION="${PLUGIN_IMAGE_VERSION}"
dokku redis:create lolipop
```

You can also specify custom environment variables to start the redis service in semi-colon separated form.

```shell
export REDIS_CUSTOM_ENV="USER=alpha;HOST=beta"
dokku redis:create lolipop
```

### print the service information

```shell
# usage
dokku redis:info <service> [--single-info-flag]
```

Get connection information as follows:

```shell
dokku redis:info lolipop
```

You can also retrieve a specific piece of service info via flags:

```shell
dokku redis:info lolipop --config-dir
dokku redis:info lolipop --data-dir
dokku redis:info lolipop --dsn
dokku redis:info lolipop --exposed-ports
dokku redis:info lolipop --id
dokku redis:info lolipop --internal-ip
dokku redis:info lolipop --links
dokku redis:info lolipop --service-root
dokku redis:info lolipop --status
dokku redis:info lolipop --version
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
dokku redis:logs <service> [-t|--tail]
```

You can tail logs for a particular service:

```shell
dokku redis:logs lolipop
```

By default, logs will not be tailed, but you can do this with the --tail flag:

```shell
dokku redis:logs lolipop --tail
```

### link the redis service to the app

```shell
# usage
dokku redis:link <service> <app> [--link-flags...]
```

A redis service can be linked to a container. This will use native docker links via the docker-options plugin. Here we link it to our 'playground' app.

> NOTE: this will restart your app

```shell
dokku redis:link lolipop playground
```

The following environment variables will be set automatically by docker (not on the app itself, so they won’t be listed when calling dokku config):

```
DOKKU_REDIS_LOLIPOP_NAME=/lolipop/DATABASE
DOKKU_REDIS_LOLIPOP_PORT=tcp://172.17.0.1:6379
DOKKU_REDIS_LOLIPOP_PORT_6379_TCP=tcp://172.17.0.1:6379
DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_PROTO=tcp
DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_PORT=6379
DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_ADDR=172.17.0.1
```

The following will be set on the linked application by default:

```
REDIS_URL=redis://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379/lolipop
```

The host exposed here only works internally in docker containers. If you want your container to be reachable from outside, you should use the 'expose' subcommand. Another service can be linked to your app:

```shell
dokku redis:link other_service playground
```

It is possible to change the protocol for redis_url by setting the environment variable redis_database_scheme on the app. Doing so will after linking will cause the plugin to think the service is not linked, and we advise you to unlink before proceeding.

```shell
dokku config:set playground REDIS_DATABASE_SCHEME=redis2
dokku redis:link lolipop playground
```

This will cause redis_url to be set as:

```
redis2://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379/lolipop
```

### unlink the redis service from the app

```shell
# usage
dokku redis:unlink <service> <app>
```

You can unlink a redis service:

> NOTE: this will restart your app and unset related environment variables

```shell
dokku redis:unlink lolipop playground
```

### Service Lifecycle

The lifecycle of each service can be managed through the following commands:

### connect to the service via the redis connection tool

```shell
# usage
dokku redis:connect <service>
```

Connect to the service via the redis connection tool:

```shell
dokku redis:connect lolipop
```

### enter or run a command in a running redis service container

```shell
# usage
dokku redis:enter <service>
```

A bash prompt can be opened against a running service. Filesystem changes will not be saved to disk.

```shell
dokku redis:enter lolipop
```

You may also run a command directly against the service. Filesystem changes will not be saved to disk.

```shell
dokku redis:enter lolipop touch /tmp/test
```

### expose a redis service on custom port if provided (random port otherwise)

```shell
# usage
dokku redis:expose <service> <ports...>
```

Expose the service on the service's normal ports, allowing access to it from the public interface (0. 0. 0. 0):

```shell
dokku redis:expose lolipop ${PLUGIN_DATASTORE_PORTS[@]}
```

### unexpose a previously exposed redis service

```shell
# usage
dokku redis:unexpose <service>
```

Unexpose the service, removing access to it from the public interface (0. 0. 0. 0):

```shell
dokku redis:unexpose lolipop
```

### promote service <service> as REDIS_URL in <app>

```shell
# usage
dokku redis:promote <service> <app>
```

If you have a redis service linked to an app and try to link another redis service another link environment variable will be generated automatically:

```
DOKKU_REDIS_BLUE_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
```

You can promote the new service to be the primary one:

> NOTE: this will restart your app

```shell
dokku redis:promote other_service playground
```

This will replace redis_url with the url from other_service and generate another environment variable to hold the previous value if necessary. You could end up with the following for example:

```
REDIS_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
DOKKU_REDIS_BLUE_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379/other_service
DOKKU_REDIS_SILVER_URL=redis://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379/lolipop
```

### start a previously stopped redis service

```shell
# usage
dokku redis:start <service>
```

Start the service:

```shell
dokku redis:start lolipop
```

### stop a running redis service

```shell
# usage
dokku redis:stop <service>
```

Stop the service and the running container:

```shell
dokku redis:stop lolipop
```

### graceful shutdown and restart of the redis service container

```shell
# usage
dokku redis:restart <service>
```

Restart the service:

```shell
dokku redis:restart lolipop
```

### upgrade service <service> to the specified versions

```shell
# usage
dokku redis:upgrade <service> [--upgrade-flags...]
```

You can upgrade an existing service to a new image or image-version:

```shell
dokku redis:upgrade lolipop
```

### Service Automation

Service scripting can be executed using the following commands:

### list all redis service links for a given app

```shell
# usage
dokku redis:app-links <app>
```

List all redis services that are linked to the 'playground' app.

```shell
dokku redis:app-links playground
```

### create container <new-name> then copy data from <name> into <new-name>

```shell
# usage
dokku redis:clone <service> <new-service> [--clone-flags...]
```

You can clone an existing service to a new one:

```shell
dokku redis:clone lolipop lolipop-2
```

### check if the redis service exists

```shell
# usage
dokku redis:exists <service>
```

Here we check if the lolipop redis service exists.

```shell
dokku redis:exists lolipop
```

### check if the redis service is linked to an app

```shell
# usage
dokku redis:linked <service> <app>
```

Here we check if the lolipop redis service is linked to the 'playground' app.

```shell
dokku redis:linked lolipop playground
```

### list all apps linked to the redis service

```shell
# usage
dokku redis:links <service>
```

List all apps linked to the 'lolipop' redis service.

```shell
dokku redis:links lolipop
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
dokku redis:import lolipop < database.dump
```

### export a dump of the redis service database

```shell
# usage
dokku redis:export <service>
```

By default, datastore output is exported to stdout:

```shell
dokku redis:export lolipop
```

You can redirect this output to a file:

```shell
dokku redis:export lolipop > lolipop.dump
```

### Backups

Datastore backups are supported via AWS S3 and S3 compatible services like [minio](https://github.com/minio/minio).

You may skip the `backup-auth` step if your dokku install is running within EC2 and has access to the bucket via an IAM profile. In that case, use the `--use-iam` option with the `backup` command.

Backups can be performed using the backup commands:

### sets up authentication for backups on the redis service

```shell
# usage
dokku redis:backup-auth <service> <aws-access-key-id> <aws-secret-access-key> <aws-default-region> <aws-signature-version> <endpoint-url>
```

Setup s3 backup authentication:

```shell
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
```

Setup s3 backup authentication with different region:

```shell
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
```

Setup s3 backup authentication with different signature version and endpoint:

```shell
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_SIGNATURE_VERSION ENDPOINT_URL
```

More specific example for minio auth:

```shell
dokku redis:backup-auth lolipop MINIO_ACCESS_KEY_ID MINIO_SECRET_ACCESS_KEY us-east-1 s3v4 https://YOURMINIOSERVICE
```

### removes backup authentication for the redis service

```shell
# usage
dokku redis:backup-deauth <service>
```

Remove s3 authentication:

```shell
dokku redis:backup-deauth lolipop
```

### creates a backup of the redis service to an existing s3 bucket

```shell
# usage
dokku redis:backup <service> <bucket-name> [--use-iam]
```

Backup the 'lolipop' service to the 'my-s3-bucket' bucket on aws:

```shell
dokku redis:backup lolipop my-s3-bucket --use-iam
```

### sets encryption for all future backups of redis service

```shell
# usage
dokku redis:backup-set-encryption <service> <passphrase>
```

Set the gpg-compatible passphrase for encrypting backups for backups:

```shell
dokku redis:backup-set-encryption lolipop
```

### unsets encryption for future backups of the redis service

```shell
# usage
dokku redis:backup-unset-encryption <service>
```

Unset the gpg encryption passphrase for backups:

```shell
dokku redis:backup-unset-encryption lolipop
```

### schedules a backup of the redis service

```shell
# usage
dokku redis:backup-schedule <service> <schedule> <bucket-name> [--use-iam]
```

Schedule a backup:

> 'schedule' is a crontab expression, eg. "0 3 * * *" for each day at 3am

```shell
dokku redis:backup-schedule lolipop "0 3 * * *" my-s3-bucket
```

Schedule a backup and authenticate via iam:

```shell
dokku redis:backup-schedule lolipop "0 3 * * *" my-s3-bucket --use-iam
```

### cat the contents of the configured backup cronfile for the service

```shell
# usage
dokku redis:backup-schedule-cat <service>
```

Cat the contents of the configured backup cronfile for the service:

```shell
dokku redis:backup-schedule-cat lolipop
```

### unschedules the backup of the redis service

```shell
# usage
dokku redis:backup-unschedule <service>
```

Remove the scheduled backup from cron:

```shell
dokku redis:backup-unschedule lolipop
```

### Disabling `docker pull` calls

If you wish to disable the `docker pull` calls that the plugin triggers, you may set the `REDIS_DISABLE_PULL` environment variable to `true`. Once disabled, you will need to pull the service image you wish to deploy as shown in the `stderr` output.

Please ensure the proper images are in place when `docker pull` is disabled.