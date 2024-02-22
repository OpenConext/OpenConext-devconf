#!/bin/bash
# Find out where we are
CWD=$(dirname $0)

read -p "This scripts needs to run only once to get a fresh install up and running. Continue? y/n " yn
case $yn in
[Nn]*)
	exit 0
	;;
*)
	echo "We are going to execute some commands"
	;;
esac

echo "First, we will initialise the EB database"
echo "Executing docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod"
docker compose exec engine /var/www/html/app/console doctrine:schema:create --env prod
echo "now we will import all the entities into manage"
for i in "$CWD"/*.json; do
	curl -k -u sysadmin:secret -H 'Content-Type: application/json' -d @$i -XPOST https://manage.dev.openconext.local/manage/api/internal/metadata
done
printf "\n"
echo "And last but not least, we are pushing the configuration from manage to eb and oidcng"
curl -k -u sysadmin:secret https://manage.dev.openconext.local/manage/api/internal/push
