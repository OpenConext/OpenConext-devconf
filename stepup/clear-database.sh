#!/bin/bash

# "clear" the database by removing the stepup_mariadb Docker volume where the database is stored

# Ask for confirmation
read -p "Are you sure you want to clear the docker database? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Aborted"
  exit 1
fi

# Get the directory of this script
# The docker-compose.yml file is stored in this directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# check if the docker compose project "stepup" is running
if [ "$(docker compose -p stepup -f ${DIR}/docker-compose.yml ps -q)" ]; then
  echo "Stopping the running stepup project"
  if ! docker compose -p stepup -f ${DIR}/docker-compose.yml down; then
    echo "Error stopping the running stepup project"
    exit 1
  fi
fi

# remove the stepup_mariadb volume
echo removing volume stepup_stepup_mariadb ...
if ! docker volume rm stepup_stepup_mariadb; then
  echo "Error removing volume stepup_stepup_mariadb"
  exit 1
fi
echo "Volume stepup_stepup_mariadb removed"
