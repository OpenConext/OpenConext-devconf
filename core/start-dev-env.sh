#!/usr/bin/env bash
set -e

# This script is used to start a development environment using docker compose
# It allows overriding app code with local directories and controlling execution mode.

RED="\e[1;31m"
GREEN="\e[1;32m"
ENDCOLOR="\e[0m"

# Clean up legacy files from previous versions of this script
rm -f .start-dev-env-listing .start-dev-env-vars

# Check if the .env file exists
if [ -f .env ]; then
  echo "Sourcing .env file"
  source .env
else
  echo -e "${GREEN}No .env file was read.${ENDCOLOR}"
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Directory where the app dirs with the app's configuration files are located
APP_DIR="${SCRIPT_DIR}"
# Name of the docker-compose override file
DOCKER_OVERRIDE_FILE="docker-compose.override.yml"

docker_compose_up_options=() # Array to hold the options for docker compose up
docker_compose_options=()    # Array to hold the options for docker compose

# Set the docker compose file to use and default profiles for Core
docker_compose_options+=("-f")
docker_compose_options+=("${SCRIPT_DIR}/docker-compose.yml")
docker_compose_options+=("--profile")
docker_compose_options+=("oidc")
docker_compose_options+=("--profile")
docker_compose_options+=("test")

# Show help hint if no arguments are given
if [ $# -eq 0 ]; then
    echo -e "${GREEN}No options were provided, use -h or --help to see the available options.${ENDCOLOR}"
fi

# Process command line arguments
while [[ $# -gt 0 ]]; do
	option="$1"

	case $option in
	-h | --help)
	    echo "Usage: $0 [-h] [-d] [<app>:<path> ...] [-- <docker-compose-args>]"
	    echo "Start the Core development environment using docker compose up"
	    echo "You can specify the apps for which you want to use the ${DOCKER_OVERRIDE_FILE} with your local code"
	    echo ""
	    echo "Options:"
	    echo "  -h, --help       Show this help message"
	    echo "  -d, --detach     Run docker compose up in detached mode (-d) with wait (--wait)"
	    echo "  <app>:<path>     The <app> to override followed by the <path> to the local code for the app"
	    echo ""
	    echo "  Any options after -- are passed to docker compose"
	    # Create a list of the subdirs of the APP_DIR directory that have a DOCKER_OVERRIDE_FILE
	    app_list=()
	    for app in "${APP_DIR}"/*; do
	        if [ -d "$app" ]; then
                app_name=$(basename "$app")
                if [ -f "${app}/${DOCKER_OVERRIDE_FILE}" ]; then
                    app_list+=("${app_name}")
                fi
            fi
	    done
	    echo ""
	    echo -e "  Available apps: ${app_list[*]}"
	    exit 0
	    ;;
    -d | --detach)
        shift
        # add "--wait" which implies -d but waits for healthchecks
        docker_compose_up_options+=("--wait")
        ;;
    --)
        shift
        # End of options for this script, everything after this is passed to docker compose
        # We need to collect the rest of the arguments
        while [[ $# -gt 0 ]]; do
            docker_compose_up_options+=("$1")
            shift
        done
        break
        ;;

	-*)
	    # Unknown option
		echo -e "${RED}Error: Unknown option: '${option}'${ENDCOLOR}"
		exit 1
		;;

	*)
	    # This must be an app:path argument
        arg="$1"
        app=$(echo "$arg" | cut -d ':' -f 1)
        path=$(echo "$arg" | cut -d ':' -f 2)

        # Basic validation
        if [[ -z "$app" ]] || [[ -z "$path" ]]; then
             echo -e "${RED}Invalid argument format: '$arg'. Expected <app>:<path>${ENDCOLOR}"
             exit 1
        fi

        # Check if the app is a valid subdirectory in the APP_DIR directory
        if ! [[ $app =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo  -e "${RED}The specified app '${app}' is not a valid name for an app.${ENDCOLOR}\n";
            exit 1;
        fi
        if [ ! -f "${APP_DIR}/${app}/${DOCKER_OVERRIDE_FILE}" ]; then
            echo  -e "${RED}The specified app '${app}' is not a valid directory/app.";
            echo  -e "Verify that '${app}' exists in '${APP_DIR}' and contains a '${DOCKER_OVERRIDE_FILE}' file.${ENDCOLOR}\n";
            exit 1;
        fi

        # Replace "~/" with the user's home directory
        path=${path/#\~/$HOME}

        # Test if the specified path(s) exist.
        if [ ! -d "${path}" ]; then
            echo  -e "${RED}The specified path for app '${app}' is not a directory.";
            echo  -e "Please verify that the '${path}' directory exists.${ENDCOLOR}\n";
            exit 1;
        fi

        # Make sure the path is absolute
        path=$(cd "${path}" && pwd)
        echo -e "${GREEN}Configuring override:${ENDCOLOR} ${app} -> ${path}"
        export "${app^^}_CODE_PATH=${path}"

        # Add the DOCKER_OVERRIDE_FILE to the docker compose command
        docker_compose_options+=("-f")
        docker_compose_options+=("${APP_DIR}/${app}/${DOCKER_OVERRIDE_FILE}")
        
        shift
	    ;;
	esac
done

# Run docker compose up command with the previously prepared options
echo -e "docker compose ${docker_compose_options[*]} up ${docker_compose_up_options[*]}"
docker compose "${docker_compose_options[@]}" up "${docker_compose_up_options[@]}"
