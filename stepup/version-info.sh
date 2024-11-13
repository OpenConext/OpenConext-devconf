#!/bin/bash

# Show the version of all the docker images used in the docker compose stepup project

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check that the docker compose "stepup" project is running by getting the ID of the project "stepup"
running=$(docker compose -p stepup -f docker-compose.yml ls --filter "name=stepup" -q)
if [ -z "$running" ]; then
    # No ID. The project is not running
    echo "Error: The docker compose project \"stepup\" must be running to get the image version information"
    exit 1
fi

# Use docker compose ps with JSON output to get the image and labels of the running containers
image_list=$(docker compose -p stepup -f "${DIR}/docker-compose.yml" ps --format json | jq -s 'sort_by(.Image) | .[] | .Image,.Labels')

# image_list is text lines with image and labels alternating:
# "image1"
# "labels1_1=value1_1,labels1_2=value1_2, ..."
# "image2"
# "labels2_1=value2_1,labels2_2=value2_2, ..."
# ...
# Get the image name and the value for the "opencontainers.image.version" label

# Table header
printf "%-10s %-21s %-13s %s\n" "Git SHA-1" "Build date" "Version" "Image"

# process the image_list
while read -r image; do
    # Remove the quotes
    image=$(echo $image | tr -d '"')
    read -r labels
    # Remove the quotes and split the labels into an array by the comma, do not split on whitespace
    labels=$(echo $labels | tr -d '"')
    IFS=',' read -r -a label_array <<< "$labels"

    version="-" # Version (git tag) of the image
    date="-"    # Date and time the image was created
    commit="-"  # Git SHA-1 commit hash of the source code used to build the image
    # Find the label with the key "org.opencontainers.image.version"
    for label in "${label_array[@]}"; do
        key=$(echo $label | cut -d= -f1)
        if [ "$key" == "org.opencontainers.image.revision" ]; then
            value=$(echo $label | cut -d= -f2)
            commit=$value
        fi
        if [ "$key" == "org.opencontainers.image.version" ]; then
            value=$(echo $label | cut -d= -f2)
            version=$value
        fi
        if [ "$key" == "org.opencontainers.image.created" ]; then
            value=$(echo $label | cut -d= -f2)
            date=$value
        fi
    done
    printf "%-10s %-21s %-13s %s\n" "${commit:0:6}" "${date:0:19}" "$version" "$image"
done <<< "$image_list"
