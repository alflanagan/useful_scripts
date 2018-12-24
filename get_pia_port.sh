#!/usr/bin/env bash
# get IP addr that starts with 10.
LOCAL_IP=$(hostname -I | grep -o '10\.[0-9]\+\.[0-9]\+\.[0-9]\+')

curl -d "user=${PIA_VPN_USER}&pass=${PIA_VPN_PASS}&client_id=$(cat ~/.pia_client_id)&local_ip=${LOCAL_IP}" https://www.privateinternetaccess.com/vpninfo/port_forward_assignment
echo
