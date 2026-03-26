#!/bin/bash
# exam_timer.sh — Cronómetro para el examen OSCP
# Uso: exam_timer.sh start    → inicia cronómetro
#      exam_timer.sh stop     → para cronómetro
#      exam_timer.sh reset    → resetea
#      exam_timer.sh toggle   → alterna start/stop
#      exam_timer.sh (sin args) → muestra tiempo (para polybar)

TIMER_FILE="/tmp/.exam_timer"
RUNNING_FILE="/tmp/.exam_timer_running"

case "$1" in
    start)
        if [ ! -f "$RUNNING_FILE" ]; then
            # Si hay un timer pausado, retomar desde donde estaba
            if [ -f "$TIMER_FILE" ]; then
                ELAPSED=$(cat "$TIMER_FILE")
                RESUME_FROM=$(($(date +%s) - ELAPSED))
                echo "$RESUME_FROM" > "$RUNNING_FILE"
            else
                echo "$(date +%s)" > "$RUNNING_FILE"
                echo "0" > "$TIMER_FILE"
            fi
            notify-send "Exam Timer" "Cronómetro iniciado" 2>/dev/null
        fi
        ;;
    stop)
        if [ -f "$RUNNING_FILE" ]; then
            START=$(cat "$RUNNING_FILE")
            NOW=$(date +%s)
            ELAPSED=$((NOW - START))
            echo "$ELAPSED" > "$TIMER_FILE"
            rm -f "$RUNNING_FILE"
            notify-send "Exam Timer" "Cronómetro pausado" 2>/dev/null
        fi
        ;;
    toggle)
        if [ -f "$RUNNING_FILE" ]; then
            $0 stop
        else
            $0 start
        fi
        ;;
    reset)
        rm -f "$TIMER_FILE" "$RUNNING_FILE"
        notify-send "Exam Timer" "Cronómetro reseteado" 2>/dev/null
        ;;
    *)
        # Display — llamado por polybar cada segundo
        if [ -f "$RUNNING_FILE" ]; then
            START=$(cat "$RUNNING_FILE")
            NOW=$(date +%s)
            ELAPSED=$((NOW - START))
            H=$((ELAPSED / 3600))
            M=$(( (ELAPSED % 3600) / 60 ))
            S=$((ELAPSED % 60))
            TIME=$(printf "%02d:%02d:%02d" $H $M $S)
            echo "%{F#6a9955}${TIME}%{F-}"
        elif [ -f "$TIMER_FILE" ]; then
            ELAPSED=$(cat "$TIMER_FILE")
            H=$((ELAPSED / 3600))
            M=$(( (ELAPSED % 3600) / 60 ))
            S=$((ELAPSED % 60))
            TIME=$(printf "%02d:%02d:%02d" $H $M $S)
            echo "%{F#d7ba7d}${TIME}%{F-}"
        else
            echo "%{F#808080}00:00:00%{F-}"
        fi
        ;;
esac
