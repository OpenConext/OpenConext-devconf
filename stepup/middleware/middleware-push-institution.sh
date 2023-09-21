#!/bin/bash

# Get this script's directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function error_exit {
	echo "${1}"
	if [ -n "${TMP_FILE}" ] && [ -d "${TMP_FILE}" ]; then
		rm "${TMP_FILE}"
	fi
	exit 1
}

# Script to write the middleware institution config

TMP_FILE=$(mktemp -t midcfg.XXXXXX)
if [ $? -ne "0" ]; then
	error_exit "Could not create temp file"
fi

echo "Pushing new institution configuration to: https://middleware.dev.openconext.local/management/institution-configuration"
echo "Reading institution configuration from: ${DIR}/middleware-institution.json";

http_response=$(curl -k --write-out %\{http_code\} --output "${TMP_FILE}" -XPOST -s \
	-u management:secret \
	-H "Accept: application/json" \
	-H "Content-type: application/json" \
	-d "@${DIR}/middleware-institution.json" \
	https://middleware.dev.openconext.local/management/institution-configuration)
res=$?

output=$(cat "${TMP_FILE}")
rm "${TMP_FILE}"
echo "$output"

if [ $res -ne "0" ]; then
	error_exit "Curl failed with code $res"
fi

# Check for HTTP 200
if [ "${http_response}" -ne "200" ]; then
	error_exit "Unexpected HTTP response: ${http_response}"
fi

# On success JSON output should start with: {"status":"OK"
ok_count=$(echo "${output}" | grep -c "status")
if [ "$ok_count" -ne "1" ]; then
	error_exit "Expected one JSON \"status: OK\" in response, found $ok_count"
fi

echo "OK. New config pushed"
