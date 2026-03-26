#!/bin/bash
# settarget — Setear o limpiar target en polybar
# Uso: settarget 10.10.10.5 Máquina   → setea
#      settarget                        → limpia
if [ -z "$1" ]; then
    echo "" > /tmp/.target
    notify-send "Target" "Target limpiado" 2>/dev/null
else
    echo "$1 $2" > /tmp/.target
    notify-send "Target" "$1 $2" 2>/dev/null
fi
