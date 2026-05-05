#!/usr/bin/env bash

# Use docker compose to stop the environment.
echo -e "Stopping the dev environment with the following command:\n"

echo -e "docker compose --profile smoketest -f docker-compose.yml down --remove-orphans $*\n"
docker compose --profile smoketest -f docker-compose.yml down --remove-orphans $*
