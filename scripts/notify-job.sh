#!/bin/bash
# notify-job — Ejecuta un comando y notifica cuando termina
# Uso: notify-job nmap -p- --open --min-rate 5000 -Pn -n -sS 10.10.10.5
#      notify-job hashcat -m 1000 hash.txt rockyou.txt
#      notify-job long_running_command args...

if [ -z "$1" ]; then
    echo "Uso: notify-job <comando> [args...]"
    echo "Ejecuta el comando y envía notificación al terminar."
    exit 1
fi

CMD_NAME="$1"
START=$(date +%s)

echo "[*] Ejecutando: $@"
"$@"
EXIT_CODE=$?

END=$(date +%s)
ELAPSED=$((END - START))
MIN=$((ELAPSED / 60))
SEC=$((ELAPSED % 60))

if [ $EXIT_CODE -eq 0 ]; then
    notify-send "Completado ✔" "$CMD_NAME terminó en ${MIN}m ${SEC}s" 2>/dev/null
    echo "[✔] $CMD_NAME terminó en ${MIN}m ${SEC}s (exit: $EXIT_CODE)"
else
    notify-send -u critical "Error ✘" "$CMD_NAME falló (exit: $EXIT_CODE) en ${MIN}m ${SEC}s" 2>/dev/null
    echo "[✘] $CMD_NAME falló en ${MIN}m ${SEC}s (exit: $EXIT_CODE)"
fi
