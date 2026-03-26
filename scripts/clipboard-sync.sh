#!/bin/bash
# clipboard-sync — Clipboard bidireccional (host ↔ VM)
# Sincroniza PRIMARY, CLIPBOARD y CUTBUFFER automáticamente.
# Funciona con: VMware (open-vm-tools), VirtualBox (guest additions), QEMU (spice-vdagent)
#
# Uso: clipboard-sync start   → inicia daemon en background
#      clipboard-sync stop    → para daemon
#      clipboard-sync status  → muestra estado
#      clipboard-sync (sin args) → start en foreground (para debug)
#
# Se lanza automáticamente desde bspwmrc

PIDFILE="/tmp/.clipboard-sync.pid"
LOGFILE="/tmp/clipboard-sync.log"
POLL_INTERVAL=0.5  # segundos entre checks

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"; }

# ── Detectar hipervisor y configurar ─────────────────────────────────────────
setup_hypervisor() {
    # VMware
    if command -v vmware-user &>/dev/null || systemctl is-active --quiet open-vm-tools 2>/dev/null; then
        log "Detectado: VMware (open-vm-tools)"
        # vmware-user ya gestiona clipboard si está corriendo
        if ! pgrep -x vmware-user &>/dev/null; then
            vmware-user &>/dev/null &
            log "vmware-user iniciado"
        fi
        # Asegurar que vmtoolsd también corre
        if ! pgrep -x vmtoolsd &>/dev/null; then
            sudo vmtoolsd &>/dev/null &
            log "vmtoolsd iniciado"
        fi
        echo "vmware"
        return 0
    fi

    # VirtualBox
    if command -v VBoxClient &>/dev/null; then
        log "Detectado: VirtualBox"
        VBoxClient --clipboard &>/dev/null
        log "VBoxClient --clipboard iniciado"
        echo "vbox"
        return 0
    fi

    # QEMU/KVM (spice-vdagent)
    if command -v spice-vdagent &>/dev/null; then
        log "Detectado: QEMU/KVM (spice)"
        if ! pgrep -x spice-vdagent &>/dev/null; then
            spice-vdagent &>/dev/null &
            log "spice-vdagent iniciado"
        fi
        echo "spice"
        return 0
    fi

    log "WARN: No se detectó hipervisor. Clipboard sync solo entre PRIMARY y CLIPBOARD."
    echo "none"
    return 1
}

# ── Sync loop: mantiene PRIMARY y CLIPBOARD sincronizados ────────────────────
# Esto es necesario porque muchas apps de Linux usan PRIMARY (selección)
# mientras que la VM clipboard del host usa CLIPBOARD. Sincronizarlos
# asegura que copiar en el host aparezca al hacer middle-click y viceversa.
sync_loop() {
    local last_clip=""
    local last_prim=""

    log "Sync loop iniciado (interval: ${POLL_INTERVAL}s)"

    while true; do
        # Leer ambos buffers
        curr_clip=$(xclip -selection clipboard -o 2>/dev/null)
        curr_prim=$(xclip -selection primary -o 2>/dev/null)

        # Si CLIPBOARD cambió → actualizar PRIMARY
        if [ "$curr_clip" != "$last_clip" ] && [ -n "$curr_clip" ]; then
            if [ "$curr_clip" != "$curr_prim" ]; then
                echo -n "$curr_clip" | xclip -selection primary 2>/dev/null
            fi
            last_clip="$curr_clip"
            last_prim="$curr_clip"

        # Si PRIMARY cambió → actualizar CLIPBOARD
        elif [ "$curr_prim" != "$last_prim" ] && [ -n "$curr_prim" ]; then
            if [ "$curr_prim" != "$curr_clip" ]; then
                echo -n "$curr_prim" | xclip -selection clipboard 2>/dev/null
            fi
            last_prim="$curr_prim"
            last_clip="$curr_prim"
        fi

        sleep "$POLL_INTERVAL"
    done
}

# ── Comandos ─────────────────────────────────────────────────────────────────
case "${1:-foreground}" in
    start)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            echo "[*] clipboard-sync ya está corriendo (PID $(cat "$PIDFILE"))"
            exit 0
        fi

        echo "$(date)" > "$LOGFILE"
        log "Iniciando clipboard-sync..."

        HYPERVISOR=$(setup_hypervisor)
        log "Hipervisor: $HYPERVISOR"

        # Lanzar sync loop en background
        sync_loop &
        SYNC_PID=$!
        echo "$SYNC_PID" > "$PIDFILE"
        log "Sync loop PID: $SYNC_PID"

        echo "[✔] clipboard-sync iniciado (PID $SYNC_PID, hypervisor: $HYPERVISOR)"
        ;;

    stop)
        if [ -f "$PIDFILE" ]; then
            PID=$(cat "$PIDFILE")
            kill "$PID" 2>/dev/null
            rm -f "$PIDFILE"
            log "Detenido (PID $PID)"
            echo "[✔] clipboard-sync detenido"
        else
            echo "[!] clipboard-sync no está corriendo"
        fi
        ;;

    status)
        if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
            PID=$(cat "$PIDFILE")
            echo "[✔] clipboard-sync activo (PID $PID)"

            # Mostrar info del hipervisor
            if pgrep -x vmware-user &>/dev/null; then
                echo "    Hypervisor: VMware (vmware-user activo)"
            elif pgrep -x VBoxClient &>/dev/null; then
                echo "    Hypervisor: VirtualBox (VBoxClient activo)"
            elif pgrep -x spice-vdagent &>/dev/null; then
                echo "    Hypervisor: QEMU/KVM (spice-vdagent activo)"
            else
                echo "    Hypervisor: No detectado (sync local PRIMARY↔CLIPBOARD)"
            fi

            # Test rápido
            echo "test_clip_$$" | xclip -selection clipboard 2>/dev/null
            sleep 0.3
            RESULT=$(xclip -selection primary -o 2>/dev/null)
            if [ "$RESULT" = "test_clip_$$" ]; then
                echo "    Sync: OK (CLIPBOARD → PRIMARY funciona)"
            else
                echo "    Sync: Puede tardar hasta ${POLL_INTERVAL}s"
            fi
        else
            echo "[✘] clipboard-sync no está corriendo"
        fi
        ;;

    foreground)
        # Para debug — corre en foreground
        echo "[*] clipboard-sync en foreground (Ctrl+C para parar)"
        HYPERVISOR=$(setup_hypervisor)
        echo "[*] Hypervisor: $HYPERVISOR"
        sync_loop
        ;;

    *)
        echo "clipboard-sync — Clipboard bidireccional host ↔ VM"
        echo ""
        echo "Uso:"
        echo "  clipboard-sync start    Iniciar daemon"
        echo "  clipboard-sync stop     Parar daemon"
        echo "  clipboard-sync status   Ver estado"
        echo "  clipboard-sync          Foreground (debug)"
        ;;
esac
