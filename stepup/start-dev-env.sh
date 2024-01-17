#!/usr/bin/env bash
# source .env so that we know when to start in test mode
source .env
if [ "${STEPUP_VERSION}" == "test" ]; then
	extra_compose_args="-f docker-compose-behat.yml"
	echo "starting in test mode"
else
	extra_compose_args=""
fi

# Read the apps and their code paths from the arguments passed to the script
docker_compose_args=()
for arg in "$@"; do
	app=$(echo $arg | cut -d ':' -f 1)
	path=$(echo $arg | cut -d ':' -f 2)
	echo "export ${app^^}_CODE_PATH=${path}" >>.start-dev-env-vars
	docker_compose_args+=("-f ./${app}/docker-compose.override.yml")
done

# Read the generated env file with the apps and their code paths
source .start-dev-env-vars
rm .start-dev-env-vars
# Use docker compose to start the environment but with the modified override file(s)
echo -e "Starting the dev environment with the following command:\n"
echo -e "docker compose -f docker-compose.yml "${docker_compose_args[@]}" "${extra_compose_args}" up "${@:3}"\n"
docker compose -f docker-compose.yml ${docker_compose_args[@]} ${extra_compose_args} up "${@:3}"
