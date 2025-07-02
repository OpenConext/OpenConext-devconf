#!/usr/bin/env bash

# This script is used to bootstrap the admin (SRAA) user in the stepup docker dev environment

# It must be run the first time after the dev environment database has been bootstrapped, before the first login of
# the "admin" user

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ask the user for an OTP from their Yubikey
echo "Please insert the Yubikey you want to use with the admin account and press press the button to generate an OTP"
read -r -p "Yubikey OTP: " otp

# The Yubikey OTP is a 44 character string, so we need to check that the length is correct
if [ ${#otp} -ne 44 ]; then
    echo "Error: The Yubikey OTP is not the correct length (44 characters)"
    exit 1
fi

# Get the Yubikey ID from the OTP. The ID is the first 12 characters of the OTP.
# The ID is ModHex encoded, so we need to decode it to get the decimal value

# Get first 12 characters of the OTP
yubikey_id_modhex=${otp:0:12}
echo "Yubikey ID (ModHex): ${yubikey_id_modhex}"
# Decode the ModHex ID to decimal
yubikey_id_hex=$(echo "${yubikey_id_modhex}" | tr 'cbdefghijklnrtuv' '0123456789abcdef')
echo "Yubikey ID (Hex): ${yubikey_id_hex}"
# Convert the hex ID to decimal
yubikey_id_dec=$((0x"${yubikey_id_hex}"))
# Prefix the ID with "0" to make it at least 8 characters long
yubikey_id=$(printf "%08d" "${yubikey_id_dec}")
echo "Yubikey ID: ${yubikey_id}"
echo ""

# Ask the user to confirm
read -r -p "Do you want to bootstrap the admin user as SRAA with Yubikey ID '${yubikey_id}'? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Aborting"
    exit 1
fi

# Change to script directory
cd "${DIR}" || exit 1

# Run middleware bootstrap console command:
echo ""
echo 'docker compose exec middleware /var/www/html/bin/console middleware:bootstrap:identity-with-yubikey urn:collab:person:dev.openconext.local:admin dev.openconext.local "Admin (SRAA)" admin@dev.openconext.local en_EN ${yubikey_id}'
docker compose exec middleware /var/www/html/bin/console middleware:bootstrap:identity-with-yubikey urn:collab:person:dev.openconext.local:admin dev.openconext.local "Admin (SRAA)" admin@dev.openconext.local en_GB ${yubikey_id}
if [ $? -ne 0 ]; then
    echo "Error: Failed to bootstrap the admin user"
    exit 1
fi

echo "Successfully bootstrapped the admin user with Yubikey ID '${yubikey_id}'"
echo "You can now login to the RA interface at https://ra.dev.openconext.local with the following credentials:"
echo "User: admin"
echo "Password: admin"
echo ""

