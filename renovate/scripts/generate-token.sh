#!/bin/bash

generate_jwt() {
  # Current timestamp and expiration (10 minutes from now)
  NOW=$(date +%s)
  EXPIRATION=$((NOW + 600))

  # Create JWT header
  HEADER='{"alg":"RS256","typ":"JWT"}'

  # Create JWT payload
  PAYLOAD="{\"iat\":${NOW},\"exp\":${EXPIRATION},\"iss\":\"$APP_ID\"}"

  # Base64 encode header and payload
  base64_header=$(echo -n "${HEADER}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
  base64_payload=$(echo -n "${PAYLOAD}" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

  # Add content of PRIVATE_KEY to private-key.pem
  echo "$PRIVATE_KEY" > /tmp/private-key.pem

  # Create signature
  signature=$(echo -n "${base64_header}.${base64_payload}" | \
  openssl dgst -sha256 -sign "/tmp/private-key.pem" | \
  openssl base64 -e -A | \
  tr '+/' '-_' | \
  tr -d '=')

  rm /tmp/private-key.pem

  # Combine all parts to create JWT
  echo "${base64_header}.${base64_payload}.${signature}"
}

# Get installation access token using JWT
get_access_token() {
  local jwt
  jwt=$(generate_jwt)

  curl -X POST \
  -H "Authorization: Bearer ${jwt}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens"
}

# Execute and get token
GITHUB_ACCESS_TOKEN=$(get_access_token | grep -o '"token": "[^"]*' | sed 's/"token": "//')

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "Failed to get GitHub access token. This is must for Renovate to work."
  exit 1
fi

echo "export RENOVATE_TOKEN='$GITHUB_ACCESS_TOKEN'" >> /tmp/secret.env
