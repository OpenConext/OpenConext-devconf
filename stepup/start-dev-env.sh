#!/usr/bin/env bash

# Read the apps and their code paths from the arguments passed to the script
docker_compose_arg=()

# Create an associative array (map) for the default paths of the apps
declare -A app_paths
app_paths["webauthn"]="../../Stepup-Webauthn"
app_paths["middleware"]="../../Stepup-Middleware"
app_paths["gateway"]="../../Stepup-Gateway"
app_paths["ra"]="../../Stepup-RA"
app_paths["tiqr"]="../../Stepup-tiqr"
app_paths["azuremfa"]="../../Stepup-Azure-MFA"

for arg in "$@"; do
    app=$(echo $arg | cut -d ':' -f 1)
    path=$(echo $arg | cut -d ':' -f 2)
    if [[ $path == $app || $path == '' ]]; then
        path=${app_paths[$app]}
    fi
    echo "export ${app^^}_CODE_PATH=${path}" >> .start-dev-env-vars
    docker_compose_args+=("-f ./${app}/docker-compose.override.yml")
done

# Read the generated env file with the apps and their code paths
source .start-dev-env-vars ; rm .start-dev-env-vars

# Use docker compose to start the environment but with the modified override file(s)
echo -e "Starting the dev environment with the following command:\n"
echo -e "docker compose -f docker-compose.yml ${docker_compose_args[@]} up "${@:3}"\n"
docker compose -f docker-compose.yml ${docker_compose_args[@]} up "${@:3}"
