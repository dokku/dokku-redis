# dokku redis (beta)

Official redis plugin for dokku. Currently installs redis 3.0.3.

## requirements

- dokku 0.3.25+
- docker 1.6.x

## installation

```
cd /var/lib/dokku/plugins
git clone https://github.com/dokku/dokku-redis.git redis
dokku plugins-install-dependencies
dokku plugins-install
```

## commands

```
redis:alias <name> <alias>     Set an alias for the docker link
redis:clone <name> <new-name>  NOT IMPLEMENTED
redis:connect <name>           Connect via redis-cli to a redis service
redis:create <name>            Create a redis service
redis:destroy <name>           Delete the service and stop its container if there are no links left
redis:export <name>            NOT IMPLEMENTED
redis:expose <name> <port>     NOT IMPLEMENTED
redis:import <name> <file>     NOT IMPLEMENTED
redis:info <name>              Print the connection information
redis:link <name> <app>        Link the redis service to the app
redis:list                     List all redis services
redis:logs <name> [-t]         Print the most recent log(s) for this service
redis:restart <name>           Graceful shutdown and restart of the service container
redis:unexpose <name> <port>   NOT IMPLEMENTED
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

# get connection information as follows
dokku redis:info lolipop

# lets assume the ip of our redis service is 172.17.0.1

# a redis service can be linked to a
# container this will use native docker
# links via the docker-options plugin
# here we link it to our 'playground' app
# NOTE: this will restart your app
dokku redis:link lolipop playground

# the above will expose the following environment variables
#
#   REDIS_URL=redis://172.17.0.1:6379
#   REDIS_NAME=/playground/DATABASE
#   REDIS_PORT=tcp://172.17.0.1:6379
#   REDIS_PORT_6379_TCP=tcp://172.17.0.1:6379
#   REDIS_PORT_6379_TCP_PROTO=tcp
#   REDIS_PORT_6379_TCP_PORT=6379
#   REDIS_PORT_6379_TCP_ADDR=172.17.0.1

# you can customize the environment
# variables through a custom docker link alias
dokku redis:alias lolipop REDIS_DATABASE

# you can also unlink a redis service
# NOTE: this will restart your app
dokku redis:unlink lolipop playground

# you can tail logs for a particular service
dokku redis:logs lolipop
dokku redis:logs lolipop -t # to tail

# finally, you can destroy the container
dokku redis:destroy playground
```

## todo

- implement redis:clone
- implement redis:expose
- implement redis:import
