#!/usr/bin/env bash

# Use docker compose to start the environment but with the modified override file(s)
echo -e "Starting the dev environment with the following command:\n"

echo -e "docker compose --profile oidc -f docker-compose.yml down\n"
docker compose --profile oidc -f docker-compose.yml down
