#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NOCOLOR='\033[0m'
CWD=$(dirname $0)
manageurl=https://manage.dev.openconext.local/manage/api/internal/

set -e

# make sure the docker environment is up
docker compose up -d --wait
# Bootstrapping engineblock means initialising the database
printf "\n"

echo -e "${ORANGE}First, we will initialise the EB database$NOCOLOR ${GREEN}\xE2\x9C\x94${NOCOLOR}"
echo "Checking if the database is already present"
engineversion=$(docker compose exec engine /var/www/html/app/console doctrine:migrations:status --env=prod |
	grep "Current Version" | awk '{print $4 }')
if [[ $engineversion == "0" ]]; then
	echo creating the database schema
	echo "Executing docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod"
	docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod
	echo "Updating engineblock to the latest migration"
	echo "Executing docker compose exec engine /var/www/html/app/console doctrine:migrations:version -n --add --all --env=prod"
	docker compose exec engine /var/www/html/app/console doctrine:migrations:version -n --add --all --env=prod
fi
echo "making sure all migrations have been executed"
echo "executing docker compose exec engine /var/www/html/app/console doctrine:migrations:migrate -n --env=prod"
docker compose exec engine /var/www/html/app/console doctrine:migrations:migrate -n --env=prod
echo "Clearing the cache"
echo "Executing docker compose exec engine /var/www/html/app/console cache:clear -n --env=prod"
docker compose exec engine /var/www/html/app/console cache:clear -n --env=prod
docker compose exec engine chown -R www-data /var/www/html/app/cache/

# Now it's time to bootstrap manage

echo -e "${ORANGE}Adding the manage entities${NOCOLOR}${GREEN} \xE2\x9C\x94${NOCOLOR}"
printf "\n"
for i in "$CWD"/*.json; do
	entityid=$(grep '"entityid":' "$i" | awk -F'"' '{print $4}')
	type=$(grep '"type":' "$i" | awk -F'"' '{print $4}')
	url="$manageurl/search/$type"
	json_body="{\"entityid\":\"$entityid\",\"REQUESTED_ATTRIBUTES\":[\"entityid\"],\"LOGICAL_OPERATOR_IS_AND\":true}"
	set +e
	command="docker compose exec managegui curl --fail-with-body -s -u sysadmin:secret -k -X POST -H \"Content-Type: application/json\" -d '$json_body' \"$url\""
	a=$(docker compose exec managegui curl --fail-with-body -s -u sysadmin:secret -k -X POST -H "Content-Type: application/json" -d "$json_body" "$url")
	if [[ $? -ne 0 ]]; then
	  echo -e "${RED}Error while adding $entityid to manage${NOCOLOR}"
	  echo $command
	  echo $a
	  exit 1
	fi
  set -e
	filename=$(basename $i)
	if [[ $a == "[]" ]]; then
		echo "$entityid not found, adding"
		docker compose exec managegui curl -s -k -u sysadmin:secret -H 'Content-Type: application/json' -d @/config/scripts/"$filename" -XPOST "$manageurl"/metadata >/dev/null
	else
		echo "$entityid already present, skipping"
	fi
done
printf "\n"
echo -e "${ORANGE}Send a PUSH in Manage, which pushes the entities to EngineBlock and OIDCNG${NOCOLOR}${GREEN} \xE2\x9C\x94${NOCOLOR}"
docker compose exec managegui curl -q -s -k -u sysadmin:secret $manageurl/push >/dev/null

printf "\n"
echo -e "${RED}Please add the following line to your /etc/hosts:${NOCOLOR}${GREEN} \xE2\x9C\x94${NOCOLOR}"
printf "\n"

echo "127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local"
