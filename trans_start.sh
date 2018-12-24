#!/usr/bin/env bash

SETTINGS_FILE="$HOME/.config/transmission/settings.json" 
CONFIG_FILE="$HOME/tmp/settings.json"
LOG_FILE="$HOME/log/transmission.log"

# get forwarded port
# get IP addr that starts with 10.
LOCAL_IP=$(hostname -I | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+')

PEER_PORT=$(curl -s -d "user=${PIA_VPN_USER}&pass=${PIA_VPN_PASS}&client_id=$(cat ~/.pia_client_id)&local_ip=${LOCAL_IP}" https://www.privateinternetaccess.com/vpninfo/port_forward_assignment)

echo "${PEER_PORT}" | grep -q "error"
HASERROR=$?
if [[ $HASERROR -eq 0 ]]; then
	echo "ERROR! ${PEER_PORT}"
	exit 1
fi

declare -i PORT_NUM
PORT_NUM=$(echo "${PEER_PORT}" | grep -o '[0-9]\+')
echo setting peer-port to "${PORT_NUM}"

NEW_SETTING='    "peer-port": '"${PORT_NUM},"

sed -e 's/    "peer-port": [0-9]\+,/'"${NEW_SETTING}"'/' "${SETTINGS_FILE}" > "${CONFIG_FILE}"

mv "${CONFIG_FILE}" "${SETTINGS_FILE}"

exec transmission-gtk > "${LOG_FILE}" 2>&1 &
