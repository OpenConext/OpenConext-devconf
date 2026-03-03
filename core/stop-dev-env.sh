#!/usr/bin/env bash

# Use docker compose to start the environment but with the modified override file(s)
echo -e "Stopping the dev environment with the following command:\n"

command='docker compose --profile oidc --profile extras --profile invite --profile php --profile dashboard --profile sbs -f docker-compose.yml down'
echo "$command"
exec $command
