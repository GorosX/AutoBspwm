#!/bin/bash
TARGET=$(cat /tmp/.target 2>/dev/null | tr -d '\n')
if [ -z "$TARGET" ] || [ "$TARGET" = " " ]; then
    echo "%{F#808080}No target%{F-}"
else
    echo "%{F#f44747}$TARGET%{F-}"
fi
