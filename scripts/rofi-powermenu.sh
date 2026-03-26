#!/bin/bash
# rofi-powermenu.sh — Power menu con rofi
# Uso: super+x desde sxhkd

OPTIONS="Bloquear\nCerrar sesión\nReiniciar\nApagar"

SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 200px;} listview {lines: 4;}')

case "$SELECTED" in
    "Bloquear")
        i3lock -c 1a1a1a 2>/dev/null || slock 2>/dev/null || xdg-screensaver lock
        ;;
    "Cerrar sesión")
        bspc quit
        ;;
    "Reiniciar")
        systemctl reboot
        ;;
    "Apagar")
        systemctl poweroff
        ;;
esac
