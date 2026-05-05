#!/usr/bin/env bash

# Use docker compose to stop the environment.
echo -e "Stopping the dev environment with the following command:\n"

command="docker compose --profile oidc --profile test --profile extras --profile invite --profile php --profile dashboard --profile sbs -f docker-compose.yml down --remove-orphans $*"
echo "$command"
exec $command
