# Instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting zsh-completions command-not-found colored-man-pages)

source $ZSH/oh-my-zsh.sh

# ── Aliases ──────────────────────────────────────────────────────────────────
alias ll='lsd -la'
alias ls='lsd'
alias cat='batcat --paging=never'
alias tree='lsd --tree'
alias grep='grep --color=auto'
alias ports='netstat -tulnp'
alias myip='ip -4 addr show tun0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
alias serve='cd ~/oscp-tools/www && sudo python3 -m http.server 80'
alias listener='rlwrap nc -nlvp'
alias nmapquick='nmap -p- --open --min-rate 5000 -Pn -n -sS'
alias nmapfull='nmap -sCV -Pn'
alias nmapudp='nmap -sU --top-ports 50 --open --min-rate 5000 -Pn -n'
alias smbserve='impacket-smbserver share . -smb2support'
alias tools='cd ~/oscp-tools'
alias htb='cd ~/Desktop/HTB'
alias pg='cd ~/Desktop/PG'

# ── Funciones ────────────────────────────────────────────────────────────────
settarget() {
    if [ -z "$1" ]; then
        echo "" > /tmp/.target
        echo "[*] Target limpiado"
    else
        echo "$1 $2" > /tmp/.target
        echo "[*] Target seteado: $1 $2"
    fi
}

mkmachine() {
    [ -z "$1" ] && echo "Uso: mkmachine <nombre>" && return 1
    mkdir -p "$1"/{scans,loot,exploits,screenshots}
    echo "[*] Estructura creada para $1"; cd "$1"
}

initscan() {
    [ -z "$1" ] && echo "Uso: initscan <IP>" && return 1
    mkdir -p scans
    nmap -p- --open --min-rate 5000 -Pn -n -sS "$1" -oN scans/tcp_quick.txt &
    nmap -sU --top-ports 50 --open --min-rate 5000 -Pn -n "$1" -oN scans/udp_quick.txt &
    echo "[*] Scans lanzados en background"
}

extractports() {
    [ -z "$1" ] && echo "Uso: extractports <nmap_file>" && return 1
    ports=$(grep '^[0-9]' "$1" | cut -d'/' -f1 | sort -u | xargs | tr ' ' ',')
    echo "$ports" | xclip -selection clipboard 2>/dev/null
    echo "[*] Puertos: $ports (copiados)"
}

export PATH="$HOME/Scripts:$HOME/oscp-tools:$HOME/oscp-tools/ad-tools:$HOME/.local/bin:$PATH"

# ── Aliases scripts nuevos ───────────────────────────────────────────────────
alias hackspace='$HOME/Scripts/hackspace.sh'
alias vpnconnect='$HOME/Scripts/vpnconnect.sh'
alias nj='notify-job'

# ── Función notify-job inline (para usar sin script) ────────────────────────
notify-job() {
    local cmd="$1"; shift
    "$cmd" "$@"
    local code=$?
    if [ $code -eq 0 ]; then
        notify-send "Completado ✔" "$cmd terminó" 2>/dev/null
    else
        notify-send -u critical "Error ✘" "$cmd falló (exit: $code)" 2>/dev/null
    fi
    return $code
}

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
