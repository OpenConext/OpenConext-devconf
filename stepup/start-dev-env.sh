#!/usr/bin/env bash
# source .env so that we know when to start in test mode
GREEN="\e[1;32m"
ENDCOLOR="\e[0m"
MODE="dev"

# Check if the .env file exists
if [ -f .env ]; then
  echo "Sourcing .env file"
  source .env
else
  echo "no .env file not found."
fi

if [ "${STEPUP_VERSION}" == "test" ]; then
	MODE="test"
	echo -e "${GREEN}Starting in test mode${ENDCOLOR}"
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
	# Test if the specified path(s) exist. If they do not, halt the script and warn
	# the user of this mistake
	if [ ! -d ${path} ]; then
	  # Not going to start the env, so clear the env listing
	  rm .start-dev-env-listing
    echo  -e "The specified path for app '${app}' is not a directory. \n";
    echo  -e "Please review: '${path}'";
    exit 1;
  fi
	echo "export ${app^^}_CODE_PATH=${path}" >>.start-dev-env-vars
	# Keep a listing of all apps that are started in dev mode, for feedback purposes
	echo "${app^^}: ${path}" >>.start-dev-env-listing
	docker_compose_args+=("-f ./${app}/docker-compose.override.yml")
	let number_of_dev_envs=number_of_dev_envs+1
done

# Because numbering is off by one, reference the next arg
let number_of_dev_envs=number_of_dev_envs+1

# See if there are .start-dev-env-vars
if [ -f .start-dev-env-vars ]; then
  # Read the generated env file with the apps and their code paths
  source .start-dev-env-vars
  rm .start-dev-env-vars
fi

if [ -f .start-dev-env-listing ]; then
  echo -e "${MODE} overrides:\n"
  cat .start-dev-env-listing
  # Remove the listing
  rm .start-dev-env-listing
fi

d_option=""
while true; do
  read -p "Do you wish to run Docker compose in the foreground? (Y/n): " yn
  yn=${yn:-y}
  case $yn in
      [Nn]* )
        d_option="-d"
        break;
        ;;
      [Yy]* )
        break;
  esac
done

# Use docker compose to start the environment but with the modified override file(s)
echo -e "Starting the ${MODE} environment with the following command:\n"

echo -e "docker compose --profile smoketest -f docker-compose.yml ${docker_compose_args[@]} ${extra_compose_args} up ${d_option} ${@:$number_of_dev_envs}\n"
docker compose --profile smoketest -f docker-compose.yml ${docker_compose_args[@]} ${extra_compose_args} up ${d_option} ${@:$number_of_dev_envs}
