#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NOCOLOR='\033[0m'
CWD=$(dirname $0)
manageurl=https://manage.dev.openconext.local/manage/api/internal/

set -e

# Bootstrapping engineblock means initialising the database
printf "\n"
echo "Bring up the engineblock container to bootstrap the database"
docker compose up -d engine mariadb
# Wait for engine to come up
docker compose exec engine timeout 300 bash -c 'while [[ "$(curl -k -s -o /dev/null -w ''%{http_code}'' localhost/info)" != "200" ]]; do sleep 5; done' || false

echo -e "${ORANGE}First, we will initialise the EB database$NOCOLOR ${GREEN}\xE2\x9C\x94${NOCOLOR}"
echo "Checking if the database is already present"
if ! docker compose exec engine /var/www/html/app/console doctrine:schema:validate -q --skip-mapping --env=prod; then
	echo creating the database schema
	echo "Executing docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod"
	docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod
#	TODO: Use migrations instead of schema:create. Not both. @see https://github.com/OpenConext/OpenConext-engineblock/issues/1861
fi
echo "Clearing the cache"
echo "Executing docker compose exec engine /var/www/html/app/console cache:clear -n --env=prod"
docker compose exec engine /var/www/html/app/console cache:clear -n --env=prod
docker compose exec engine chown -R www-data:www-data /var/www/html/app/cache/

# Now it's time to bootstrap manage
# Bring up containers needed for bootstrapping manage
docker compose --profile oidc up -d --wait
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

echo "127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local invite.dev.openconext.local welcome.dev.openconext.local"

printf "\n"
echo "You can now login. If you want to bring the environment down, use the command below"
echo "docker compose --profile oidc down"
printf "\n"
