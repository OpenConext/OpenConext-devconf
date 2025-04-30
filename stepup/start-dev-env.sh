#!/usr/bin/env bash

# This script is used to start a development environment using docker compose
# There are several ways to control this script:
# 1. By passing arguments to the script
# 2. By setting environment variables in the .env file
# 3. By setting environment variables in the shell before running the script

# This script monitors the following environment variables:
# - STEPUP_VERSION: The version of the stepup project to use. Can be set to 'test'
# - APP_ENV:        The environment to use. If set to 'smoketest', the --profile smoketest option is passed to docker
#                   compose
# You can set these variables in an .env file in the local directory or in the shell before running this script.

# This script accepts arguments in the form of <app>:<path> that allows you to start the container for the specified
# application with you local code mounted in the container.
# This works by including the docker-compose.override.yml file for the specified application and setting an environment
# variable <app>_CODE_PATH with the path to the local code that is used in the docker-compose.override.yml file to
# mount the local code in the container.

# Finally any arguments after -- are passed to the docker compose up command

RED="\e[1;31m"
GREEN="\e[1;32m"
ORANGE="\e[1;33m"
ENDCOLOR="\e[0m"

# Check if the .env file exists
if [ -f .env ]; then
  echo "Sourcing .env file"
  source .env
else
  echo -e "${GREEN}No .env file was read.${ENDCOLOR}"
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Directory where the app dirs with the app's configuration files and - relevant for us - the docker-compose.override.yml
# files are located
APP_DIR="${SCRIPT_DIR}"
# Name of the docker-compose override file
DOCKER_OVERRIDE_FILE="docker-compose.override.yml"

docker_compose_up_options=() # Array to hold the options for docker compose up
docker_compose_options=()    # Array to hold the options for docker compose

# Set the docker compose file to use
docker_compose_options+=("-f")
docker_compose_options+=("${SCRIPT_DIR}/docker-compose.yml")

# Add some default options for the docker compose up command
docker_compose_up_options+=("--wait")  # Wait for the containers to be ready


# Show value of STEPUP_VERSION and APP_ENV if set and process their values
# Warn if these values are not set to unexpected values
if [ -n "${STEPUP_VERSION}" ]; then
  echo "STEPUP_VERSION=${STEPUP_VERSION}"
  # Warn if the version is not 'test'
  if [ "${STEPUP_VERSION}" != "test" ]; then
    echo -e "${ORANGE}Warning: STEPUP_VERSION is not set to 'test'${ENDCOLOR}"
  fi
fi
if [ -n "${APP_ENV}" ]; then
  echo "APP_ENV=${APP_ENV}"
    # Use docker compose with the smoketest profile when APP_ENV=smoketest
    if [ "${APP_ENV}" == "smoketest" ]; then
        docker_compose_options+=("--profile")
        docker_compose_options+=("smoketest")
        echo -e "${GREEN}Setting Docker profile to 'smoketest' because APP_ENV=smoketest${ENDCOLOR}"
    else
        # Warn if the environment is not 'smoketest'
        echo -e "${ORANGE}Warning: APP_ENV is not set to 'smoketest', not specifying a Docker profile${ENDCOLOR}"
    fi
fi

# Show help hint if no arguments are given
if [ $# -eq 0 ]; then
    echo -e "${GREEN}No options were provided, use -h or --help to see the available options.${ENDCOLOR}"
fi

# Process command line arguments
# First process the options until the first argument (app:path or --) is found
while [[ $# -gt 0 ]]; do
	option="$1"

	case $option in
	-h | --help)
	    echo "Usage: $0 [-h] [-d] [<app>:<path> ...] [-- <docker-compose-args>]"
	    echo "Start the development environment using docker compose up"
        echo "You can specify the apps for which you want to use the ${DOCKER_OVERRIDE_FILE} with your local code"
        echo ""
        echo "Options:"
        echo "  -h, --help       Show this help message"
        echo "  -d               Run docker compose up in detached mode"
        echo "  <app>:<path>     The <app> to override followed by the <path> to the local code for the app"
        echo ""
        echo "  Any options after -- are passed to docker compose"
        # Create a list of the subdirs of the APP_DIR directory that have a DOCKER_OVERRIDE_FILE
        app_list=()
        for app in "${APP_DIR}"/*; do
            app_name=$(basename $app)
            if [ -f "${app}/${DOCKER_OVERRIDE_FILE}" ]; then
                app_list+=("${app_name}")
            fi
        done
        echo ""
        echo -e "  Available apps: ${app_list[*]}"
        exit 0
        ;;
    -d | --detach)
        shift
        # add "-d" to docker_compose_up_options
        docker_compose_up_options+=("-d")
        ;;
    --)
        # End of options for this script, everything after this is passed to docker compose
        break
        ;;

	-*)
	    # Unknown option
		echo -e "${RED}Error: Unknown option: '${option}'${ENDCOLOR}"
		exit 1
		;;

	*)
	    # This must be an app:path argument, we will process it below
	    break
	    ;;
	esac
done

# Read the apps and their code paths from the arguments passed to the script
# The arguments should be in the format <app>:<path>
# Where <app> is the name of the app and <path> is the path to the code
# The app names are the subdirectories in the APP_DIR directory
while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ $arg == "--" ]]; then
        shift
        # The rest of the arguments are passed to docker compose
        break
    fi
	app=$(echo "$arg" | cut -d ':' -f 1)
	path=$(echo ""$arg | cut -d ':' -f 2)
	# Check if the app is a valid subdirectory in the APP_DIR directory, it must contain a DOCKER_OVERRIDE_FILE
	# app must be a string without spaces, special characters or slashes
	if ! [[ $app =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo  -e "${RED}The specified app '${app}' is not a valid name for an app.${ENDCOLOR}\n";
        exit 1;
    fi
	if [ ! -f "${app}/${DOCKER_OVERRIDE_FILE}" ]; then
        echo  -e "${RED}The specified app '${app}' is not a valid directory.";
        echo  -e "Verify that '${app}' exists in '${APP_DIR}' and contains a '${DOCKER_OVERRIDE_FILE}' file.${ENDCOLOR}\n";
        exit 1;
    fi

	# Test if the specified path(s) exist.
	if [ ! -d "${path}" ]; then
        echo  -e "${RED}The specified path for app '${app}' is not a directory.";
        echo  -e "Please verify that the '${path}' directory exists.${ENDCOLOR}\n";
        exit 1;
    fi

    shift

    # Make sure the path is absolute and export a <app>_CODE_PATH variable for use in the app's DOCKER_OVERRIDE_FILE
    path=$(eval cd "${path}"; pwd)
    echo "export ${app^^}_CODE_PATH='${path}'"
	eval "export ${app^^}_CODE_PATH='${path}'"

	# Add the DOCKER_OVERRIDE_FILE to the docker compose command
	docker_compose_options+=("-f")
	docker_compose_options+=("${APP_DIR}/${app}/${DOCKER_OVERRIDE_FILE}")
done

# Add any remaining command line arguments to the docker_compose_up_options
if [ $# -gt 0 ]; then
    # Add the remaining arguments to the docker_compose_up_options
    docker_compose_up_options+=("$@")
fi

# Run docker compose up command with the previously prepared options
echo -e "docker compose ${docker_compose_options[*]} up ${docker_compose_up_options[*]}"
docker compose "${docker_compose_options[@]}" up "${docker_compose_up_options[@]}"
