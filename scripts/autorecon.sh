#!/bin/bash
# autorecon — Escaneo automático organizado
# Uso: autorecon <IP>
# Lanza: nmap TCP rápido → extrae puertos → nmap detallado → nmap UDP → scripts vuln

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${CYAN}autorecon${NC} — Escaneo automático OSCP"
    echo "Uso: autorecon <IP>"
    exit 1
fi

IP="$1"
DIR="scans"
mkdir -p "$DIR"

echo -e "${CYAN}[*]${NC} Escaneando ${GREEN}$IP${NC}..."
echo -e "${CYAN}[*]${NC} Resultados en ./$DIR/"

# ── Fase 1: TCP rápido ──────────────────────────────────────────────────────
echo -e "\n${YELLOW}[1/4]${NC} TCP scan rápido (todos los puertos)..."
nmap -p- --open --min-rate 5000 -Pn -n -sS "$IP" -oN "$DIR/tcp_quick.txt" -oG "$DIR/tcp_quick.gnmap" 2>/dev/null

# Extraer puertos
PORTS=$(grep '^[0-9]' "$DIR/tcp_quick.txt" 2>/dev/null | cut -d'/' -f1 | sort -u | xargs | tr ' ' ',')

if [ -z "$PORTS" ]; then
    echo -e "${RED}[!]${NC} No se encontraron puertos TCP abiertos"
else
    echo -e "${GREEN}[✔]${NC} Puertos TCP: ${CYAN}$PORTS${NC}"
    echo "$PORTS" | xclip -selection clipboard 2>/dev/null

    # ── Fase 2: TCP detallado ────────────────────────────────────────────────
    echo -e "\n${YELLOW}[2/4]${NC} TCP scan detallado (-sCV)..."
    nmap -p"$PORTS" -sCV -Pn "$IP" -oN "$DIR/tcp_detail.txt" 2>/dev/null
    echo -e "${GREEN}[✔]${NC} TCP detallado completado"
fi

# ── Fase 3: UDP top ports ───────────────────────────────────────────────────
echo -e "\n${YELLOW}[3/4]${NC} UDP scan (top 50 puertos)..."
sudo nmap -sU --top-ports 50 --open --min-rate 5000 -Pn -n "$IP" -oN "$DIR/udp_quick.txt" 2>/dev/null &
UDP_PID=$!

# ── Fase 4: Vuln scan (en background) ───────────────────────────────────────
if [ -n "$PORTS" ]; then
    echo -e "${YELLOW}[4/4]${NC} Vuln scan (background)..."
    nmap -p"$PORTS" --script vuln -Pn "$IP" -oN "$DIR/vuln_scan.txt" 2>/dev/null &
    VULN_PID=$!
fi

# Esperar UDP
wait $UDP_PID 2>/dev/null
UDP_PORTS=$(grep '^[0-9]' "$DIR/udp_quick.txt" 2>/dev/null | cut -d'/' -f1 | sort -u | xargs | tr ' ' ',')
if [ -n "$UDP_PORTS" ]; then
    echo -e "${GREEN}[✔]${NC} Puertos UDP: ${CYAN}$UDP_PORTS${NC}"
else
    echo -e "${YELLOW}[i]${NC} No se encontraron puertos UDP abiertos"
fi

# Resumen
echo -e "\n${GREEN}══════════════════════════════════════${NC}"
echo -e "${GREEN}[✔]${NC} Escaneo principal completado"
echo -e "${CYAN}    TCP:${NC} $PORTS"
echo -e "${CYAN}    UDP:${NC} ${UDP_PORTS:-ninguno}"
echo -e "${CYAN}    Dir:${NC} ./$DIR/"
echo -e "${GREEN}══════════════════════════════════════${NC}"

if [ -n "$VULN_PID" ]; then
    echo -e "${YELLOW}[i]${NC} Vuln scan sigue en background (PID $VULN_PID)"
fi

# Notificación de escritorio
notify-send "autorecon" "Escaneo de $IP completado — TCP: $PORTS" 2>/dev/null
