#!/bin/bash

set -e

# Get this script's directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Initializing middleware and gateway databases"
docker compose exec middleware /var/www/html/bin/console  doctrine:migrations:migrate --env=prod --em=deploy --no-interaction
docker compose exec middleware chown -R www-data /var/www/html/var/cache

echo "Initializing webauthn database"
docker compose exec webauthn /var/www/html/bin/console doctrine:migrations:migrate --env=prod --no-interaction
docker compose exec webauthn chown -R www-data /var/www/html/var/cache

echo "Pushing middleware configuration"
sh "${DIR}/middleware/middleware-push-config.sh"

echo "Pushing middleware whitelist"
sh "${DIR}/middleware/middleware-push-whitelist.sh"

echo "Pushing middleware institution configuration"
sh "${DIR}/middleware/middleware-push-institution.sh"

echo "Done"