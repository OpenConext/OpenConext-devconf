#!/usr/bin/env bash

# Download the current mds metadata from the fido mds site and put it in the webauthn container

# Get the directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create tmp filename for the downloaded mds
tmp_file=$(mktemp /tmp/fido-mds.XXXXXX)

# Use curl to download the MDS file
MDS_URL="https://mds.fidoalliance.org/"
MDS_TARGET="${DIR}/webauthn/blob.jwt"
echo "Downloading ${MDS_URL}"
if ! curl -fsSL \
    --retry 2 \
    --retry-delay 10 \
    --retry-max-time 30 \
    --retry-all-errors \
    -o "$tmp_file" \
    "$MDS_URL"; then
    echo "Error downloading FIDO MDS metadata file"
    rm -f "$tmp_file"
    exit 1
fi

if ! grep -Eq '^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$' "$tmp_file"; then
    echo "Error the FIDO MDS payload does not look like a JWT blob."
    rm -f "$tmp_file"
    exit 1
fi

if ! cp "$tmp_file" "$MDS_TARGET"; then
    echo "Error copying FIDO MDS metadata file mounted in webauthn container"
    rm -f "$tmp_file"
    exit 1
fi

echo "Wrote mds file to ${MDS_TARGET}"

echo "Restarting container"
if ! docker compose -f "${DIR}/docker-compose.yml" restart webauthn; then
    echo "The container could not be restarted"
fi

# Clean up
rm -f "$tmp_file"

echo "Successfully updated FIDO MDS"
