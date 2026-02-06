#!/usr/bin/env bash
set -euo pipefail


# ---- config file ----
CONFIG_FILE="/etc/tailscale-service.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"

# ---- required variables ----
REQUIRED_VARS=(
  OAUTH_CLIENT_ID
  OAUTH_CLIENT_SECRET
  TAILNET
  SERVICENAME
  INTERFACE
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing or empty variable in config file: $var" >&2
    exit 1
  fi
done

command -v jq >/dev/null || {
  echo "jq is required but not installed" >&2
  exit 1
}

until ip link show tailscale0 | grep -q "UP"; do
  sleep 1
done

# ---- added due to NS caching issue ----
nslookup api.tailscale.com

# ---- get OAuth token ----
token_response=$(
  curl -sS -X POST \
    -d "client_id=${OAUTH_CLIENT_ID}" \
    -d "client_secret=${OAUTH_CLIENT_SECRET}" \
    "https://api.tailscale.com/api/v2/oauth/token"
)

ACCESS_TOKEN=$(jq -r '.access_token' <<<"$token_response")

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "Failed to obtain access token" >&2
  echo "$token_response" >&2
  exit 1
fi

# ---- fetch service details ----
service_response=$(
  curl -sS \
    "https://api.tailscale.com/api/v2/tailnet/${TAILNET}/services/${SERVICENAME}" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}"
)

# ---- extract IP addresses ----
mapfile -t IP_ADDRS < <(jq -r '.addrs[]' <<<"$service_response")

if [[ "${#IP_ADDRS[@]}" -eq 0 ]]; then
  echo "No IP addresses found for service ${SERVICENAME}" >&2
  echo "$service_response" >&2
  exit 1
fi

# ---- add IPs to interface ----
for ip in "${IP_ADDRS[@]}"; do
  echo "Adding ${ip} to ${INTERFACE}"
if ! ip addr show dev "$INTERFACE" | grep -q "$ip"; then
  ip a add "$ip" dev "$INTERFACE"
else
 echo "${ip} already added"
fi

done
