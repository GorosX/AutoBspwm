#!/bin/bash
# vpnconnect — Conectar a VPN de HTB, OffSec o archivo .ovpn
# Uso: vpnconnect htb          → conecta al .ovpn de HTB en ~/vpn/
#      vpnconnect offsec        → conecta al .ovpn de OffSec en ~/vpn/
#      vpnconnect <archivo.ovpn> → conecta a cualquier .ovpn
#      vpnconnect stop          → desconecta VPN activa
#      vpnconnect status        → muestra estado

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
VPN_DIR="$HOME/vpn"

case "$1" in
    htb)
        OVPN=$(find "$VPN_DIR" -iname "*htb*" -o -iname "*hackthebox*" 2>/dev/null | grep -i "\.ovpn$" | head -1)
        if [ -z "$OVPN" ]; then
            echo -e "${RED}[!]${NC} No se encontró .ovpn de HTB en ~/vpn/"
            echo "    Descarga tu .ovpn de HTB y guárdalo en ~/vpn/"
            exit 1
        fi
        echo -e "${GREEN}[*]${NC} Conectando a HTB: $(basename "$OVPN")"
        sudo openvpn "$OVPN" &
        sleep 3
        VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        [ -n "$VPN_IP" ] && echo -e "${GREEN}[✔]${NC} Conectado: $VPN_IP" && notify-send "VPN" "HTB conectado: $VPN_IP" 2>/dev/null
        ;;
    offsec|pg)
        OVPN=$(find "$VPN_DIR" -iname "*offsec*" -o -iname "*offensive*" -o -iname "*pen-200*" -o -iname "*pwk*" 2>/dev/null | grep -i "\.ovpn$" | head -1)
        if [ -z "$OVPN" ]; then
            echo -e "${RED}[!]${NC} No se encontró .ovpn de OffSec en ~/vpn/"
            echo "    Descarga tu .ovpn del portal de OffSec y guárdalo en ~/vpn/"
            exit 1
        fi
        echo -e "${GREEN}[*]${NC} Conectando a OffSec: $(basename "$OVPN")"
        sudo openvpn "$OVPN" &
        sleep 3
        VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        [ -n "$VPN_IP" ] && echo -e "${GREEN}[✔]${NC} Conectado: $VPN_IP" && notify-send "VPN" "OffSec conectado: $VPN_IP" 2>/dev/null
        ;;
    stop|kill|disconnect)
        sudo killall openvpn 2>/dev/null
        echo -e "${GREEN}[✔]${NC} VPN desconectada"
        notify-send "VPN" "Desconectado" 2>/dev/null
        ;;
    status)
        VPN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        if [ -n "$VPN_IP" ]; then
            echo -e "${GREEN}[✔]${NC} VPN activa: $VPN_IP"
        else
            echo -e "${RED}[✘]${NC} Sin VPN"
        fi
        ;;
    *.ovpn)
        if [ -f "$1" ]; then
            echo -e "${GREEN}[*]${NC} Conectando: $1"
            sudo openvpn "$1" &
        else
            echo -e "${RED}[!]${NC} Archivo no encontrado: $1"
        fi
        ;;
    *)
        echo -e "${CYAN}vpnconnect${NC} — Conexión rápida a VPN"
        echo ""
        echo "Uso:"
        echo "  vpnconnect htb           Conectar a HackTheBox"
        echo "  vpnconnect offsec        Conectar a OffSec/PG"
        echo "  vpnconnect <file.ovpn>   Conectar a cualquier .ovpn"
        echo "  vpnconnect stop          Desconectar VPN"
        echo "  vpnconnect status        Ver estado"
        echo ""
        echo "Los archivos .ovpn deben estar en ~/vpn/"
        ;;
esac
