#!/bin/bash

# Initialise stepup database schemas: middleware, gateway, webauthn
# Note: tiqr is not included in this script

# This script is idempotent, if run a second time it upgrades the Doctrine managed schema's (middleware, gateway, webauthn)
# to the latest versions and push the latest middleware configuration, whitelist and institution configuration

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check that the docker compose "stepup" project is running by getting the ID of the project "stepup"
running=$(docker compose -p stepup -f docker-compose.yml ls --filter "name=stepup" -q)
if [ -z "$running" ]; then
    # No ID. The project is not running
    echo "Error: The docker compose project \"stepup\" is not running"
    exit 1
fi

# Initialize the middleware & gateway database schemas
echo "Initializing/upgrading the middleware & gateway database schemas"
if ! docker compose -f "${DIR}/docker-compose.yml" exec middleware /var/www/html/bin/console doctrine:migrations:migrate --env=prod --em=deploy --no-interaction; then
    echo "Error initializing the middleware & gateway database schemas"
    echo ""
    exit 1
fi
echo "Middleware & gateway database schemas initialized/upgraded"
echo ""

# WebAuthn migrations are currently broken

# Initialize the webauthn database schema
echo "Initializing/upgrading the webauthn database schema"
if ! docker compose -f "${DIR}/docker-compose.yml" exec webauthn php /var/www/html/bin/console doctrine:migrations:migrate --env=prod --no-interaction; then
    echo "Error initializing the webauthn database schema"
    echo ""
    exit 1
fi
echo "Webauthn database schemas initialized/upgraded"
echo ""

# Push middleware configuration
echo "Pushing new middleware configuration"
if ! "${DIR}/middleware/middleware-push-config.sh"; then
    echo "Error pushing new middleware configuration"
    echo ""
    exit 1
fi
echo ""

echo "Pushing new institution whitelist"
if ! "${DIR}/middleware/middleware-push-whitelist.sh"; then
    echo "Error pushing new institution whitelist"
    echo ""
    exit 1
fi
echo ""

echo "Pushing new institution configuraton"
if ! "${DIR}/middleware/middleware-push-institution.sh"; then
    echo "Error pushing new institution whitelist"
    echo ""
    exit 1
fi
echo ""
