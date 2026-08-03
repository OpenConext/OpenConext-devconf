#!/usr/bin/env bash
set -euo pipefail

# Seeds a fully vetted Demo GSSP identity directly via Middleware's command API,
# bypassing registration UI, RA app, e-mail, and any physical/virtual second factor
# hardware entirely. Mirrors the "has a vetted demo-gssp" step in
# tests/behat/features/bootstrap/FeatureContext.php (theUserHasAVettedWithIdentifier),
# adapted from the smoketest DB to this environment's real dev DB/credentials.
#
# Usage: ./seed-test-identity.sh <slug> [institution] [gssf-id]
#
# After running, log in via the ssp test SP (https://ssp.dev.openconext.local/simplesaml/sp.php)
# as <slug>/<slug>, request an LoA that Demo GSSP satisfies, and pick "Demo GSSP" as the
# second factor -- no registration/vetting/hardware step needed.

SLUG="${1:?Usage: $0 <slug> [institution] [gssf-id]}"
INSTITUTION="${2:-dev.openconext.local}"
GSSF_ID="${3:-seed-$SLUG}"
NAME_ID="urn:collab:person:${INSTITUTION}:${SLUG}"
IDENTITY_ID=$(uuidgen | tr 'A-Z' 'a-z')
SECOND_FACTOR_ID=$(uuidgen | tr 'A-Z' 'a-z')

# Real SRAA identity in this environment's dev DB (has RA authority everywhere).
# Look it up fresh rather than hardcoding, in case the admin identity_id ever changes.
ACTOR_ID=$(docker exec stepup-mariadb-1 mysql -uroot -psecret middleware -N -B \
  -e "SELECT id FROM identity WHERE name_id='urn:collab:person:dev.openconext.local:admin';")

if [ -z "$ACTOR_ID" ]; then
  echo "Could not find the admin/SRAA identity in the middleware DB -- is the environment bootstrapped?" >&2
  exit 1
fi

MW=https://middleware.dev.openconext.local
DB="docker exec stepup-mariadb-1 mysql -uroot -psecret -N -B middleware"

post() {
  local user=$1 pass=$2 body=$3
  curl -sk -u "$user:$pass" -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST "$MW/command" -d "$body"
  echo
}

echo "== Creating identity $NAME_ID ($IDENTITY_ID) =="
post ss sa_secret "$(printf '{"meta":{"actor_id":null,"actor_institution":null},"command":{"name":"Identity:CreateIdentity","uuid":"%s","payload":{"id":"%s","name_id":"%s","institution":"%s","email":"%s@dev.openconext.local","common_name":"%s","preferred_locale":"en_GB"}}}' \
  "$(uuidgen)" "$IDENTITY_ID" "$NAME_ID" "$INSTITUTION" "$SLUG" "$SLUG")"

echo "== Proving possession of Demo GSSP token (gssf_id=$GSSF_ID) =="
post ss sa_secret "$(printf '{"meta":{"actor_id":"%s","actor_institution":"%s"},"command":{"name":"Identity:ProveGssfPossession","uuid":"%s","payload":{"identity_id":"%s","second_factor_id":"%s","stepup_provider":"demo_gssp","gssf_id":"%s"}}}' \
  "$IDENTITY_ID" "$INSTITUTION" "$(uuidgen)" "$IDENTITY_ID" "$SECOND_FACTOR_ID" "$GSSF_ID")"

# Unlike yubikey/sms, GSSF possession (Identity:ProveGssfPossession) is proven-and-verified
# in a single event (GssfPossessionProvenAndVerifiedEvent) -- no separate e-mail/nonce step.
REG_CODE=$($DB -e "SELECT registration_code FROM verified_second_factor WHERE identity_id='$IDENTITY_ID' ORDER BY registration_requested_at DESC LIMIT 1;")
if [ -z "$REG_CODE" ]; then
  echo "No verified_second_factor row found for $IDENTITY_ID -- VerifyEmail likely failed, see output above." >&2
  exit 1
fi

echo "== Vetting (registration code $REG_CODE, authority $ACTOR_ID) =="
post ra ra_secret "$(printf '{"meta":{"actor_id":"%s","actor_institution":"%s"},"command":{"name":"Identity:VetSecondFactor","uuid":"%s","payload":{"authority_id":"%s","identity_id":"%s","second_factor_id":"%s","registration_code":"%s","second_factor_type":"demo_gssp","second_factor_identifier":"%s","document_number":"123456","identity_verified":true}}}' \
  "$ACTOR_ID" "$INSTITUTION" "$(uuidgen)" "$ACTOR_ID" "$IDENTITY_ID" "$SECOND_FACTOR_ID" "$REG_CODE" "$GSSF_ID")"

VETTED=$($DB -e "SELECT id FROM vetted_second_factor WHERE identity_id='$IDENTITY_ID';")
echo
if [ -n "$VETTED" ]; then
  echo "Done. $SLUG now has a vetted Demo GSSP token (second_factor_id=$VETTED)."
  echo "Log in at https://ssp.dev.openconext.local/simplesaml/sp.php as ${SLUG}/${SLUG}, pick a Request LOA Demo GSSP satisfies, and select Demo GSSP as the second factor."
else
  echo "Vetting did not produce a vetted_second_factor row -- check the command output above for an error." >&2
  exit 1
fi
