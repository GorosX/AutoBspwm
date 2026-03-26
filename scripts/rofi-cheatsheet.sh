#!/bin/bash
# rofi-cheatsheet — Busca comandos y copia al clipboard
# Uso: rofi-cheatsheet (se llama desde sxhkd con super+shift+c)

CHEATSHEET="$HOME/Scripts/cheatsheet.txt"

if [ ! -f "$CHEATSHEET" ]; then
    notify-send "Error" "cheatsheet.txt no encontrado" 2>/dev/null
    exit 1
fi

# Mostrar descripciones en rofi, al seleccionar copiar el comando
SELECTED=$(awk -F' \\| ' '{print $1}' "$CHEATSHEET" | rofi -dmenu -i -p "Cheatsheet" -theme-str 'window {width: 50%;} listview {lines: 15;}')

if [ -n "$SELECTED" ]; then
    CMD=$(grep "^$SELECTED |" "$CHEATSHEET" | head -1 | awk -F' \\| ' '{print $2}')
    if [ -n "$CMD" ]; then
        echo -n "$CMD" | xclip -selection clipboard
        notify-send "Copiado" "$CMD" 2>/dev/null
    fi
fi
