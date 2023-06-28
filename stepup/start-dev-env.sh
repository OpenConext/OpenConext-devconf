#!/usr/bin/env bash

# Read the command line parameters to configure the dev env
export SERVICE=$1
export CODE_PATH=$2

# Use docker compose to start the environment but with the modified override file
docker-compose -f docker-compose.yml -f ./${SERVICE}/docker-compose.override.yml up
