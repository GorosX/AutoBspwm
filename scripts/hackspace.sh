#!/bin/bash
# hackspace — Abre tmux con layout de hacking
# Panel grande arriba (trabajo), abajo-izq (listener), abajo-der (notas)
# Uso: hackspace [nombre_sesion]

SESSION="${1:-hack}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach -t "$SESSION"
    exit 0
fi

tmux new-session -d -s "$SESSION" -x "$(tput cols)" -y "$(tput lines)"

# Panel principal arriba (70% altura)
tmux split-window -v -p 30 -t "$SESSION"

# Split panel inferior en dos
tmux split-window -h -t "$SESSION":1.1

# Panel 0 (arriba): directorio de trabajo
tmux send-keys -t "$SESSION":1.0 'cd ~/Desktop && clear' C-m

# Panel 1 (abajo-izq): listener
tmux send-keys -t "$SESSION":1.1 'echo "[*] Panel para listener — rlwrap nc -nlvp 4444"' C-m

# Panel 2 (abajo-der): notas/comandos
tmux send-keys -t "$SESSION":1.2 'echo "[*] Panel de notas/comandos rápidos"' C-m

# Foco en panel principal
tmux select-pane -t "$SESSION":1.0

tmux attach -t "$SESSION"
