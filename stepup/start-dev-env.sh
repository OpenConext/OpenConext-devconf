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

# Keep a counter of the number of dev-envs to override
number_of_dev_envs=0
for arg in "$@"; do
	app=$(echo $arg | cut -d ':' -f 1)
	path=$(echo $arg | cut -d ':' -f 2)
	echo "export ${app^^}_CODE_PATH=${path}" >>.start-dev-env-vars
	# Keep a listing of all apps that are started in dev mode, for feedback purposes
	echo "${app^^}: ${path}" >>.start-dev-env-listing
	docker_compose_args+=("-f ./${app}/docker-compose.override.yml")
	let number_of_dev_envs=number_of_dev_envs+1
done

# Because numbering is off by one, reference the next arg
let number_of_dev_envs=number_of_dev_envs+1
# Read the generated env file with the apps and their code paths
source .start-dev-env-vars
rm .start-dev-env-vars
# Use docker compose to start the environment but with the modified override file(s)

echo -e "Dev overrides:\n"
cat .start-dev-env-listing

# Remove the listing
rm .start-dev-env-listing

echo -e "Starting the dev environment with the following command:\n"

while true; do
    read -p "Do you wish to run Docker compose in the foreground? " yn
    case $yn in
        [Yy]* )
          echo -e "docker compose -f docker-compose.yml "${docker_compose_args[@]}" "${extra_compose_args}" up "${@:$number_of_dev_envs}"\n"
          docker compose -f docker-compose.yml ${docker_compose_args[@]} ${extra_compose_args} up "${@:$number_of_dev_envs}"
          break;;
        [Nn]* )
          echo -e "docker compose -f docker-compose.yml "${docker_compose_args[@]}" "${extra_compose_args}" up -d "${@:$number_of_dev_envs}"\n"
                    docker compose -f docker-compose.yml ${docker_compose_args[@]} ${extra_compose_args} up -d "${@:$number_of_dev_envs}"
          break;;
        * ) echo "Please answer yes or no.";;
    esac
done

