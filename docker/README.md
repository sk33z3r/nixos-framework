# Docker NixOS Framework

Each service here generally pulls in the `common.nix` file so that a universal maintenance helper script is available. A few configs have special needs and define their own scripts without pulling in common.

## Service Script

Each service script consolidates an otherwise lengthy docker-compose command down to the following universal commands for each service:

```
up          | Runs docker-compose up -d
update      | Pulls latest images, then runs docker-compose up -d --force-recreate
down        | Runs docker-compose down
restart     | Runs docker-compose restart
build       | Runs docker-compose build for the main container in the deployment (not all configs can be built locally)
logs        | Tails the last 25 lines and follows the container's logs
```