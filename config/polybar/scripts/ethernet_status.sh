#!/bin/bash
# ethernet_status.sh — Detecta VPN activa y muestra IP + tipo
# Para polybar: muestra "HTB: 10.10.14.x" o "OFFSEC: 192.168.x.x" o "VPN: x.x.x.x"

VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$VPN_IP" ]; then
    echo "No VPN"
    exit 0
fi

# Detectar tipo de VPN por rango de IP
if echo "$VPN_IP" | grep -qE "^10\.10\.(14|15|16|17)\."; then
    echo "HTB $VPN_IP"
elif echo "$VPN_IP" | grep -qE "^192\.168\.(45|49|51)\."; then
    echo "PG $VPN_IP"
elif echo "$VPN_IP" | grep -qE "^10\.13\.|^10\.11\."; then
    echo "OSCP $VPN_IP"
else
    echo "VPN $VPN_IP"
fi
