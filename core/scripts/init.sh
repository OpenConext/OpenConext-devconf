#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NOCOLOR='\033[0m'
VINKJE="${GREEN}✔${NOCOLOR}"
CWD=$(dirname $0)
manageurl=https://manage.dev.openconext.local/manage/api/internal/

set -e

# Bootstrapping engineblock means initialising the database
printf "\n"
echo -e "${ORANGE}Bring up the engineblock Production container to bootstrap the database using the Production container's migrations${NOCOLOR}"
echo "Comment the two lines below to run the migrations from your own running engine container (ensure your EB is running)."
echo

# Wait for engine to come up; not health yet because we might nee to initialialize db
docker compose up -d engine mariadb
docker compose exec engine timeout 300 bash -c 'while [[ "$(curl -k -s -o /dev/null -w ''%{http_code}'' localhost/internal/info)" != "200" ]]; do sleep 5; done' || false

echo
echo -e "${ORANGE}Initializing EB database$NOCOLOR ${VINKJE}"
echo
echo "Running database migrations"
cmd='docker compose exec engine /var/www/html/bin/console doctrine:migrations:migrate --no-interaction'
${cmd}

echo "Clearing the cache"
docker compose exec engine /var/www/html/bin/console cache:clear -n --env=prod
docker compose exec engine chown -R www-data:www-data /var/www/html/var/cache/

echo -ne "Waiting for EB to be healthy..."
until [ "$(docker inspect -f {{.State.Health.Status}} $(docker compose ps -q engine))" == "healthy" ]
do
	echo -n "."
	sleep 0.5;
done
echo -e " ${VINKJE}"

# Now it's time to bootstrap manage
# Bring up containers needed for bootstrapping manage
echo
echo -e "${ORANGE}Bring up the core containers${NOCOLOR} ${VINKJE}"
echo
docker compose --profile oidc up -d --wait
echo

echo -e "${ORANGE}Adding the manage entities${NOCOLOR} ${VINKJE}"
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
echo -e "${ORANGE}Send a PUSH in Manage, which pushes the entities to EngineBlock and OIDCNG ${VINKJE}"
docker compose exec managegui curl -q -s -k -u sysadmin:secret $manageurl/push >/dev/null

printf "\n"
echo -e "${BLUE}Please add the following line to your /etc/hosts: ${VINKJE}"
printf "\n"

echo "127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local invite.dev.openconext.local welcome.dev.openconext.local"

printf "\n"
echo "You can now login. If you want to bring the environment down, use the command below"
echo "docker compose --profile oidc down"
printf "\n"
