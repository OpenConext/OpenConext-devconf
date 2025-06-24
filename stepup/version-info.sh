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

# Use docker compose ps with JSON output to get the image, service name and labels of the running containers
image_list=$(docker compose -p stepup -f "${DIR}/docker-compose.yml" ps --format json | jq -s 'sort_by(.Service) | .[] | .Image,.Service,.Labels')

# image_list is text lines with service, image and labels alternating:
# "image1"
# "service1"
# "labels1_1=value1_1,labels1_2=value1_2, ..."
# "image2"
# "service2"
# "labels2_1=value2_1,labels2_2=value2_2, ..."
# ...

# Table header
printf "%-12s %-20s %-10s %-21s %-13s %s\n" "Service" "Title" "Git SHA-1" "Build date" "Version" "Image"

# process the image_list
while read -r image; do
    image=$(echo "${image}" | tr -d '"') # Remove the quotes

    read -r service
    service=$(echo "${service}" | tr -d '"') # Remove the quotes

    read -r labels
    # Remove the quotes and split the labels into an array by comma
    labels=$(echo "${labels}" | tr -d '"')
    IFS=',' read -r -a label_array <<< "$labels"

    title="-"   # Image title (org.opencontainers.image.title)
    version="-" # Version (git tag) of the image
    date="-"    # Date and time the image was created
    commit="-"  # Git SHA-1 commit hash of the source code used to build the image
    # Find the label with the key "org.opencontainers.image.version"
    for label in "${label_array[@]}"; do
        key=$(echo "${label}" | cut -d= -f1)
        if [ "$key" == "org.opencontainers.image.title" ]; then
            value=$(echo "${label}" | cut -d= -f2)
            title=$value
        fi
        if [ "$key" == "org.opencontainers.image.revision" ]; then
            value=$(echo "${label}" | cut -d= -f2)
            commit=$value
        fi
        if [ "$key" == "org.opencontainers.image.version" ]; then
            value=$(echo "${label}" | cut -d= -f2)
            version=$value
        fi
        if [ "$key" == "org.opencontainers.image.created" ]; then
            value=$(echo "${label}" | cut -d= -f2)
            # Date is formatted in ISO, convert to local timezone
            date=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${value}Z" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "${value}Z" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$value")
        fi
    done
    printf "%-12s %-20s %-10s %-21s %-13s %s\n" "${service:0:12}" "${title:0:19}" "${commit:0:6}" "${date:0:19}" "$version" "$image"
done <<< "$image_list"
