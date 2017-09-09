# dokku redis (beta)  [![Build Status](https://img.shields.io/travis/dokku/dokku-redis.svg?branch=master "Build Status")](https://travis-ci.org/dokku/dokku-redis) [![IRC Network](https://img.shields.io/badge/irc-freenode-blue.svg "IRC Freenode")](https://webchat.freenode.net/?channels=dokku)

Official redis plugin for dokku. Currently defaults to installing [redis 3.2.8](https://hub.docker.com/_/redis/).

## requirements

- dokku 0.4.x+
- docker 1.8.x

## installation

```shell
# on 0.4.x+
sudo dokku plugin:install https://github.com/dokku/dokku-redis.git redis
```

## commands

```
redis:backup <name> <bucket> (--use-iam) Create a backup of the redis service to an existing s3 bucket
redis:backup-auth <name> <aws_access_key_id> <aws_secret_access_key> (<aws_default_region>) (<aws_signature_version>) (<endpoint_url>) Sets up authentication for backups on the redis service
redis:backup-deauth <name>     Removes backup authentication for the redis service
redis:backup-schedule <name> <schedule> <bucket> Schedules a backup of the redis service
redis:backup-set-encryption <name> <encryption_key>, Sets up GPG encryption for future backups of the redis service
redis:backup-unschedule <name> Unschedules the backup of the redis service
redis:backup-unset-encryption <name>, Removes backup encryption for future backups of the redis service
redis:clone <name> <new-name>  Create container <new-name> then copy data from <name> into <new-name>
redis:connect <name>           Connect via redis-cli to a redis service
redis:create <name>            Create a redis service with environment variables
redis:destroy <name>           Delete the service, delete the data and stop its container if there are no links left
redis:enter <name> [command]   Enter or run a command in a running redis service container
redis:export <name> > <file>   Export a dump of the redis service database
redis:expose <name> [port]     Expose a redis service on custom port if provided (random port otherwise)
redis:import <name> <file>     Import a dump into the redis service database
redis:info <name>              Print the connection information
redis:link <name> <app>        Link the redis service to the app
redis:list                     List all redis services
redis:logs <name> [-t]         Print the most recent log(s) for this service
redis:promote <name> <app>     Promote service <name> as REDIS_URL in <app>
redis:restart <name>           Graceful shutdown and restart of the redis service container
redis:start <name>             Start a previously stopped redis service
redis:stop <name>              Stop a running redis service
redis:unexpose <name>          Unexpose a previously exposed redis service
redis:unlink <name> <app>      Unlink the redis service from the app
```

## usage

```shell
# create a redis service named lolipop
dokku redis:create lolipop

# you can also specify the image and image
# version to use for the service
# it *must* be compatible with the
# official redis image
export REDIS_IMAGE="redis"
export REDIS_IMAGE_VERSION="2.8.21"
dokku redis:create lolipop

# you can also specify custom environment
# variables to start the redis service
# in semi-colon separated form
export REDIS_CUSTOM_ENV="USER=alpha;HOST=beta"
dokku redis:create lolipop

# get connection information as follows
dokku redis:info lolipop

# you can also retrieve a specific piece of service info via flags
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

# a bash prompt can be opened against a running service
# filesystem changes will not be saved to disk
dokku redis:enter lolipop

# you may also run a command directly against the service
# filesystem changes will not be saved to disk
dokku redis:enter lolipop ls -lah /

# a redis service can be linked to a
# container this will use native docker
# links via the docker-options plugin
# here we link it to our 'playground' app
# NOTE: this will restart your app
dokku redis:link lolipop playground

# the following environment variables will be set automatically by docker (not
# on the app itself, so they won’t be listed when calling dokku config)
#
#   DOKKU_REDIS_LOLIPOP_NAME=/lolipop/DATABASE
#   DOKKU_REDIS_LOLIPOP_PORT=tcp://172.17.0.1:6379
#   DOKKU_REDIS_LOLIPOP_PORT_6379_TCP=tcp://172.17.0.1:6379
#   DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_PROTO=tcp
#   DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_PORT=6379
#   DOKKU_REDIS_LOLIPOP_PORT_6379_TCP_ADDR=172.17.0.1
#
# and the following will be set on the linked application by default
#
#   REDIS_URL=redis://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379
#
# NOTE: the host exposed here only works internally in docker containers. If
# you want your container to be reachable from outside, you should use `expose`.

# another service can be linked to your app
dokku redis:link other_service playground

# since REDIS_URL is already in use, another environment variable will be
# generated automatically
#
#   DOKKU_REDIS_BLUE_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379

# you can then promote the new service to be the primary one
# NOTE: this will restart your app
dokku redis:promote other_service playground

# this will replace REDIS_URL with the url from other_service and generate
# another environment variable to hold the previous value if necessary.
# you could end up with the following for example:
#
#   REDIS_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379
#   DOKKU_REDIS_BLUE_URL=redis://other_service:ANOTHER_PASSWORD@dokku-redis-other-service:6379
#   DOKKU_REDIS_SILVER_URL=redis://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379/lolipop

# you can also unlink a redis service
# NOTE: this will restart your app and unset related environment variables
dokku redis:unlink lolipop playground

# you can tail logs for a particular service
dokku redis:logs lolipop
dokku redis:logs lolipop -t # to tail

# you can dump the database
dokku redis:export lolipop > lolipop.rdb

# you can import a dump
dokku redis:import lolipop < database.rdb

# you can clone an existing database to a new one
dokku redis:clone lolipop new_database

# finally, you can destroy the container
dokku redis:destroy lolipop
```

## Changing database adapter

It's possible to change the protocol for REDIS_URL by setting
the environment variable REDIS_DATABASE_SCHEME on the app:

```
dokku config:set playground REDIS_DATABASE_SCHEME=redis2
dokku redis:link lolipop playground
```

Will cause REDIS_URL to be set as
redis2://lolipop:SOME_PASSWORD@dokku-redis-lolipop:6379/lolipop

CAUTION: Changing REDIS_DATABASE_SCHEME after linking will cause dokku to
believe the redis is not linked when attempting to use `dokku redis:unlink`
or `dokku redis:promote`.
You should be able to fix this by

- Changing REDIS_URL manually to the new value.

OR

- Set REDIS_DATABASE_SCHEME back to its original setting
- Unlink the service
- Change REDIS_DATABASE_SCHEME to the desired setting
- Relink the service

## Backups

Datastore backups are supported via AWS S3 and S3 compatible services like [minio](https://github.com/minio/minio).

You may skip the `backup-auth` step if your dokku install is running within EC2
and has access to the bucket via an IAM profile. In that case, use the `--use-iam`
option with the `backup` command.

Backups can be performed using the backup commands:

```
# setup s3 backup authentication
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

# remove s3 authentication
dokku redis:backup-deauth lolipop

# backup the `lolipop` service to the `BUCKET_NAME` bucket on AWS
dokku redis:backup lolipop BUCKET_NAME

# schedule a backup
# CRON_SCHEDULE is a crontab expression, eg. "0 3 * * *" for each day at 3am
dokku redis:backup-schedule lolipop CRON_SCHEDULE BUCKET_NAME

# remove the scheduled backup from cron
dokku redis:backup-unschedule lolipop
```

Backup auth can also be set up for different regions, signature versions and endpoints (e.g. for minio):
 
```
# setup s3 backup authentication with different region
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
 
# setup s3 backup authentication with different signature version and endpoint
dokku redis:backup-auth lolipop AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION AWS_SIGNATURE_VERSION ENDPOINT_URL
 
# more specific example for minio auth
dokku redis:backup-auth lolipop MINIO_ACCESS_KEY_ID MINIO_SECRET_ACCESS_KEY us-east-1 s3v4 https://YOURMINIOSERVICE
```
