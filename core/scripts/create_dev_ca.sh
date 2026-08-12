#!/usr/bin/env bash

set -euo pipefail

# Create a private CA that issues one (wildcard) server certificate
# Reduce the risks introduced by (accidentally) adding the CA certificate to a developer's trust store:
# - Delete the CA's private key after issuing the server certificate to prevent additional certificates
#   from being issued (i.e. signed) by the CA
# - Add a critical nameConstraint extension to the CA certificate restricting it to localhost and the
#   intended domain
#
# This script works on OSX and Linux. Requires bash >= 4, openssl >= 3

#### Configuration ####
# Will issue a wildcard (star) TLS server certificate for this DNS domain
# Do not add the "*". E.g. "example.com"
CERT_DOMAIN='dev.openconext.local'

# Validity of the TLS server certificate in days
# The current CA/browser forum limit for end-entity certificates is 398
CERT_VALID_DAYS=398

# A name to identity the CA. The CA_NAME is used as part of the CA's Subject DN.
# E.g. "ACME dev CA"
CA_NAME="OpenConext dev CA"
#### End configuration ####

# Create a temporary working dir for holding private key, etc
# Add a trap to ensure it is deleted
TMPDIR="$(mktemp -d "devca.XXXXXXXX")"
chmod 700 "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT INT TERM

# Add the current date and time (UTC) to the CA_NAME to make it identifiable
CA_NAME+=" ($(date -u '+%Y-%m-%d %H:%M:%S UTC'))"

# Nameconstraint extension for in the CA certificate
NC_EXT="critical"  # critical: A client MUST fail if it does not understand this extension
NC_EXT+=",permitted;DNS:.${CERT_DOMAIN}"  # Allow issuing for DNS domain only
NC_EXT+=",excluded;IP:0.0.0.0/0.0.0.0"  # Exclude all IPv4
NC_EXT+=",excluded;IP:0:0:0:0:0:0:0:0/0:0:0:0:0:0:0:0"  # Exclude all IPv6

CA_VALID_DAYS=$((CERT_VALID_DAYS + 1)) # Nr of days that the CA certificate is valid

# Create the CA
# Use secp384r1 (NIST P-384) for the key and sign with SHA-384
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -noenc \
	-keyout "$TMPDIR/ca.key" -out "$TMPDIR/ca.crt" \
	-days "$CA_VALID_DAYS" -sha384 \
	-subj "/CN=${CA_NAME}" \
	-addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
	-addext "keyUsage=critical,keyCertSign" \
	-addext "nameConstraints=${NC_EXT}" \
	-addext "subjectKeyIdentifier=hash" \
	-config /dev/null
chmod 400 "$TMPDIR/ca.key"

# Print CA certificate
openssl x509 -in "$TMPDIR/ca.crt" -noout -text

# Create the TLS server certificate wildcard certificate for the domain
# Use the P-256 (NIST) curve
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -noenc \
	-keyout "$TMPDIR/cert.key" -out "$TMPDIR/cert.crt" \
	-CA "$TMPDIR/ca.crt" -CAkey "$TMPDIR/ca.key" \
	-days "$CERT_VALID_DAYS" -sha256 \
	-subj "/CN=*.${CERT_DOMAIN}" \
	-addext "keyUsage=critical,digitalSignature" \
	-addext "extendedKeyUsage=serverAuth" \
	-addext "subjectAltName=DNS:*.${CERT_DOMAIN}" \
	-addext "subjectKeyIdentifier=hash" \
	-addext "authorityKeyIdentifier=keyid:always" \
	-config /dev/null
chmod 400 "$TMPDIR/cert.key"

# We don't want to issue any more certificates with this CA
rm -f "$TMPDIR/ca.key"

# Print the server certificate
openssl x509 -in "$TMPDIR/cert.crt" -noout -text

# Copy certificate into the haproxy config
# haproxy.crt: the CA certificate for others to trust, this pushed into the containers at startup
# haproxy.pem: the server certificate and key for haproxy itself.
# The order of the components must for haproxy must be:
# - Server certificate
# - Intermediate (which we do not have)
# - CA certificate
# - Server certificate private key
SCRIPT_DIR=$(dirname $0)
HAPROXY_CORE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/../haproxy" && pwd -P)"

# CA Cert for use by the containers
cp "$TMPDIR/ca.crt" "$HAPROXY_CORE_DIR/haproxy.crt"
chmod 644 "$HAPROXY_CORE_DIR/haproxy.crt"
echo "Wrote $HAPROXY_CORE_DIR/haproxy.crt"

# HAProxy cert
cp "$TMPDIR/cert.crt" "$HAPROXY_CORE_DIR/haproxy.pem"
chmod 644 "$HAPROXY_CORE_DIR/haproxy.crt"
cat "$TMPDIR/ca.crt" >> "$HAPROXY_CORE_DIR/haproxy.pem"
cat "$TMPDIR/cert.key" >> "$HAPROXY_CORE_DIR/haproxy.pem"
echo "Wrote $HAPROXY_CORE_DIR/haproxy.pem"

rm -rf "$TMPDIR"
