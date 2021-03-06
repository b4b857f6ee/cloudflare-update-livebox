#!/bin/bash

# Forked from benkulbertis/cloudflare-update-record.sh
# CHANGE THESE
#auth_email="john.appleseed@example.org"            # The email used to login 'https://dash.cloudflare.com'
#auth_key="f1nd7h47fuck1n6k3y1ncl0udfl4r3c0n50l3"   # Top right corner, "My profile" > "Global API Key"
#zone_identifier="f1nd7h3fuck1n6z0n31d3n71f13r4l50" # Can be found in the "Overview" tab of your domain
#record_name="ipv4.example.org"                    # Which record you want to be synced

# DO NOT CHANGE LINES BELOW (Check using Livebox v4 API)
ip=$(curl -s -X POST -H "Content-Type: application/json" -d '{"parameters":{}}'  http://192.168.1.1/sysbus/NMC:getWANStatus | sed -e 's/.*"IPAddress":"\(.*\)","Remo.*/\1/g')

# SCRIPT START
echo "[Cloudflare DDNS] Check Initiated"

# Seek for the record
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

# Can't do anything without the record
if [[ $record == *"\"count\":0"* ]]; then
  >&2 echo -e "[Cloudflare DDNS] Record does not exist, perhaps create one first?"
  exit 1
fi

# Set existing IP address from the fetched record
old_ip=$(echo "$record" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

# Compare if they're the same
if [[ $ip == $old_ip ]]; then
  echo "[Cloudflare DDNS] IP has not changed."
  exit 0
fi

# Set the record identifier from result
record_identifier=$(echo "$record" | grep -oP '\"id\":\"\K([^"]*)')

# The execution of update
update=$(curl -s -X PATCH https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"proxied\":true,\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":120}")

# The moment of truth
case "$update" in
*"\"success\":false"*)
  >&2 echo -e "[Cloudflare DDNS] Update failed for $record_identifier. DUMPING RESULTS:\n$update"
  exit 1;;
*)
  echo "[Cloudflare DDNS] IPv4 context '$ip' has been synced to Cloudflare.";;
esac
