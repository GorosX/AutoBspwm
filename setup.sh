#!/bin/bash

#============================================================================
#  AutoBSPWM-OSCP — Setup completo
#  NO ejecutar como root. El script pide sudo cuando lo necesita.
#  Uso: chmod +x setup.sh && ./setup.sh
#============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_ok()   { echo -e "${GREEN}[✔]${NC} $1"; }
log_info() { echo -e "${BLUE}[i]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_step() { echo -e "\n${BOLD}${CYAN}══════ $1 ══════${NC}\n"; }
log_dl()   { echo -e "    ${CYAN}↓${NC} $1"; }

safe_download() {
    wget -q --timeout=15 "$1" -O "$2" 2>/dev/null && log_dl "$(basename "$2")" || { log_warn "$(basename "$2")"; rm -f "$2"; }
}
safe_clone() {
    [ ! -d "$2" ] && git clone --depth=1 -q "$1" "$2" 2>/dev/null && log_dl "$(basename "$2")" || true
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}[!] NO ejecutar como root. Usa: ./setup.sh${NC}"; exit 1
fi

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        AutoBSPWM-OSCP — Entorno completo para Kali         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

TOOLS="$HOME/oscp-tools"
WIN="$TOOLS/windows"; LIN="$TOOLS/linux"; AD="$TOOLS/ad-tools"
WEB="$TOOLS/webshells"; WWW="$TOOLS/www"
EXP="$TOOLS/exploits"

mkdir -p "$TOOLS"/{windows,linux,webshells,ad-tools,enum,www}
mkdir -p "$EXP"/{ftp,smb,web,ad,linux-privesc,windows-privesc,tunneling,misc}
mkdir -p "$HOME"/{Desktop/{HTB,PG,VulnLab},Scripts}

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 1/10: Actualización y dependencias"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y \
    build-essential git curl wget unzip p7zip-full \
    libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev \
    libxcb-util0-dev libxcb-ewmh-dev libxcb-keysyms1-dev \
    libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev \
    libxcb-composite0-dev libxcb-image0-dev libxcb-xkb-dev \
    libxcb-xrm-dev libxcb-cursor-dev libxcb1-dev \
    cmake cmake-data pkg-config python3-xcbgen xcb-proto \
    libcairo2-dev libasound2-dev libpulse-dev libjsoncpp-dev \
    libmpdclient-dev libcurl4-openssl-dev libnl-genl-3-dev \
    libdbus-1-dev libuv1-dev libiw-dev \
    xorg xserver-xorg xinit imagemagick feh rofi dunst \
    zsh fonts-powerline fonts-font-awesome \
    bat lsd locate net-tools xdotool xdo wmctrl xclip xsel scrot flameshot \
    jq tree tmux \
    open-vm-tools-desktop spice-vdagent
log_ok "Dependencias instaladas"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 2/10: Compilar bspwm + sxhkd"
cd /tmp
if ! command -v bspwm &>/dev/null; then
    rm -rf bspwm && git clone https://github.com/baskerville/bspwm.git
    cd bspwm && make -j$(nproc) && sudo make install && cd /tmp
    log_ok "bspwm compilado"
else log_ok "bspwm ya instalado"; fi

if ! command -v sxhkd &>/dev/null; then
    rm -rf sxhkd && git clone https://github.com/baskerville/sxhkd.git
    cd sxhkd && make -j$(nproc) && sudo make install && cd /tmp
    log_ok "sxhkd compilado"
else log_ok "sxhkd ya instalado"; fi

sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=bspwm
Comment=bspwm
Exec=bspwm
Type=Application
EOF

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 3/10: Picom + Polybar + Kitty"
sudo apt install -y picom polybar kitty i3lock tmux openvpn
log_ok "Instalados"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 4/10: ZSH + Oh My Zsh + Powerlevel10k"

# Usuario
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZC="$HOME/.oh-my-zsh/custom"
[ ! -d "$ZC/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZC/themes/powerlevel10k"
[ ! -d "$ZC/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZC/plugins/zsh-autosuggestions"
[ ! -d "$ZC/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZC/plugins/zsh-syntax-highlighting"
[ ! -d "$ZC/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions "$ZC/plugins/zsh-completions"

# Root
if [ ! -f "/root/.oh-my-zsh/oh-my-zsh.sh" ]; then
    sudo rm -rf /root/.oh-my-zsh
    sudo sh -c 'RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
fi
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k 2>/dev/null || true
sudo git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null || true
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null || true

sudo chsh -s /usr/bin/zsh "$USER"
sudo chsh -s /usr/bin/zsh root
log_ok "ZSH + p10k instalados"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 5/10: Nerd Fonts"
if [ ! -d "/usr/local/share/fonts/NerdFonts" ]; then
    sudo mkdir -p /usr/local/share/fonts/NerdFonts && cd /tmp
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -O Hack.zip
    sudo unzip -o Hack.zip -d /usr/local/share/fonts/NerdFonts 2>/dev/null && rm -f Hack.zip
    sudo fc-cache -fv > /dev/null 2>&1
fi
log_ok "Nerd Fonts instaladas"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 6/10: Copiar dotfiles"

mkdir -p "$HOME/.config"/{bspwm,sxhkd,polybar/scripts,picom,kitty,dunst}
mkdir -p "$HOME/vpn"

cp -v "$SCRIPT_DIR/config/bspwm/bspwmrc"                "$HOME/.config/bspwm/"
cp -v "$SCRIPT_DIR/config/sxhkd/sxhkdrc"                "$HOME/.config/sxhkd/"
cp -v "$SCRIPT_DIR/config/polybar/config.ini"            "$HOME/.config/polybar/"
cp -v "$SCRIPT_DIR/config/polybar/launch.sh"             "$HOME/.config/polybar/"
cp -v "$SCRIPT_DIR/config/polybar/scripts/"*             "$HOME/.config/polybar/scripts/"
cp -v "$SCRIPT_DIR/config/picom/picom.conf"              "$HOME/.config/picom/"
cp -v "$SCRIPT_DIR/config/kitty/kitty.conf"              "$HOME/.config/kitty/"
cp -v "$SCRIPT_DIR/config/dunst/dunstrc"                 "$HOME/.config/dunst/"
cp -v "$SCRIPT_DIR/.zshrc"                               "$HOME/.zshrc"
cp -v "$SCRIPT_DIR/.p10k.zsh"                            "$HOME/.p10k.zsh"
cp -v "$SCRIPT_DIR/.tmux.conf"                           "$HOME/.tmux.conf"

# Scripts
cp -v "$SCRIPT_DIR/scripts/"*.sh                         "$HOME/Scripts/"
cp -v "$SCRIPT_DIR/scripts/cheatsheet.txt"               "$HOME/Scripts/"

# Wallpaper
cp "$SCRIPT_DIR/wallpapers/"* "$HOME/.config/bspwm/" 2>/dev/null || true

# Permisos
chmod +x "$HOME/.config/bspwm/bspwmrc"
chmod +x "$HOME/.config/polybar/launch.sh"
chmod +x "$HOME/.config/polybar/scripts/"*.sh
chmod +x "$HOME/Scripts/"*.sh

# Root dotfiles
sudo cp "$SCRIPT_DIR/.p10k.zsh" /root/.p10k.zsh
sudo cp "$SCRIPT_DIR/.tmux.conf" /root/.tmux.conf
sudo tee /root/.zshrc > /dev/null << 'ROOTZSH'
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="/root/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting colored-man-pages)
source $ZSH/oh-my-zsh.sh
alias ll='lsd -la'; alias ls='lsd'; alias cat='batcat --paging=never'
alias myip='ip -4 addr show tun0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}"'
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ROOTZSH

# Firefox bookmarks
cp "$SCRIPT_DIR/config/firefox/bookmarks.html" "$HOME/oscp-bookmarks.html"

log_ok "Dotfiles copiados"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 7/10: Herramientas OSCP (apt + pip)"

sudo apt install -y \
    nmap gobuster feroxbuster nikto whatweb wpscan \
    hydra john hashcat sqlmap ffuf netexec \
    smbclient smbmap enum4linux rpcclient ldap-utils \
    netcat-traditional bloodhound neo4j \
    sshuttle evil-winrm responder rlwrap \
    python3-impacket impacket-scripts \
    seclists wordlists exploitdb \
    onesixtyone snmp dnsrecon nbtscan \
    mingw-w64 webshells proxychains4 \
    python3-pip python3-venv pipx ftp

pip3 install --break-system-packages certipy-ad bloodhound pwncat-cs pypykatz name-that-hash bloodyAD coercer git-dumper 2>/dev/null

[ -f /usr/share/wordlists/rockyou.txt.gz ] && sudo gunzip -k /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true

# Proxychains
if ! grep -q "socks5 127.0.0.1 1080" /etc/proxychains4.conf 2>/dev/null; then
    sudo cp /etc/proxychains4.conf /etc/proxychains4.conf.bak
    sudo sed -i 's/^socks4.*/# &/' /etc/proxychains4.conf
    echo "socks5 127.0.0.1 1080" | sudo tee -a /etc/proxychains4.conf > /dev/null
fi
log_ok "Herramientas OSCP instaladas"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 8/10: Enum + PrivEsc binarios"

log_info "Linux enum..."
safe_download "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" "$LIN/linpeas.sh"
safe_download "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64" "$LIN/pspy64"
safe_download "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" "$LIN/linux-exploit-suggester.sh"
safe_download "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" "$LIN/LinEnum.sh"
safe_download "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" "$LIN/lse.sh"
chmod +x "$LIN"/* 2>/dev/null

log_info "Windows enum + privesc..."
safe_download "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASany.exe" "$WIN/winPEASany.exe"
safe_download "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1" "$WIN/PowerView.ps1"
safe_download "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" "$WIN/PowerUp.ps1"
safe_download "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" "$WIN/Seatbelt.exe"
safe_download "https://live.sysinternals.com/accesschk64.exe" "$WIN/accesschk64.exe"
safe_download "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET4.exe" "$WIN/GodPotato-NET4.exe"
safe_download "https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer64.exe" "$WIN/PrintSpoofer64.exe"
safe_download "https://github.com/ohpe/juicy-potato/releases/latest/download/JuicyPotato.exe" "$WIN/JuicyPotato.exe"
safe_download "https://github.com/antonioCoco/RunasCs/releases/latest/download/RunasCs.zip" "$WIN/RunasCs.zip"
[ -f "$WIN/RunasCs.zip" ] && cd "$WIN" && unzip -o RunasCs.zip -d RunasCs 2>/dev/null && rm -f RunasCs.zip; cd -
safe_download "https://github.com/itm4n/FullPowers/releases/latest/download/FullPowers.exe" "$WIN/FullPowers.exe"
cp /usr/share/windows-resources/binaries/nc.exe "$WIN/" 2>/dev/null
log_ok "Enum + PrivEsc descargados"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 9/10: AD tools + Tunneling + Exploits"

log_info "AD tools..."
safe_download "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe" "$AD/Rubeus.exe"
safe_download "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Certify.exe" "$AD/Certify.exe"
safe_download "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64" "$AD/kerbrute"
chmod +x "$AD/kerbrute" 2>/dev/null
safe_download "https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip" "$AD/mimikatz.zip"
[ -f "$AD/mimikatz.zip" ] && cd "$AD" && unzip -o mimikatz.zip -d mimikatz 2>/dev/null && rm -f mimikatz.zip; cd -
safe_clone "https://github.com/topotam/PetitPotam.git" "$EXP/ad/PetitPotam"
safe_clone "https://github.com/Ridter/noPac.git" "$EXP/ad/noPac"
safe_clone "https://github.com/dirkjanm/PKINITtools.git" "$EXP/ad/PKINITtools"

log_info "Tunneling..."
CHISEL_VER=$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4 | tr -d 'v')
if [ -n "$CHISEL_VER" ]; then
    safe_download "https://github.com/jpillora/chisel/releases/download/v${CHISEL_VER}/chisel_${CHISEL_VER}_linux_amd64.gz" "$EXP/tunneling/chisel_linux.gz"
    [ -f "$EXP/tunneling/chisel_linux.gz" ] && gunzip -f "$EXP/tunneling/chisel_linux.gz" && chmod +x "$EXP/tunneling/chisel_linux"
    safe_download "https://github.com/jpillora/chisel/releases/download/v${CHISEL_VER}/chisel_${CHISEL_VER}_windows_amd64.gz" "$EXP/tunneling/chisel_win.gz"
    [ -f "$EXP/tunneling/chisel_win.gz" ] && gunzip -f "$EXP/tunneling/chisel_win.gz"
fi

LIGOLO_VER=$(curl -s https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest 2>/dev/null | grep tag_name | cut -d'"' -f4 | tr -d 'v')
if [ -n "$LIGOLO_VER" ]; then
    safe_download "https://github.com/nicocha30/ligolo-ng/releases/download/v${LIGOLO_VER}/ligolo-ng_proxy_${LIGOLO_VER}_linux_amd64.tar.gz" "$EXP/tunneling/lp.tar.gz"
    [ -f "$EXP/tunneling/lp.tar.gz" ] && tar xf "$EXP/tunneling/lp.tar.gz" -C "$EXP/tunneling" 2>/dev/null && rm -f "$EXP/tunneling/lp.tar.gz"
    safe_download "https://github.com/nicocha30/ligolo-ng/releases/download/v${LIGOLO_VER}/ligolo-ng_agent_${LIGOLO_VER}_linux_amd64.tar.gz" "$EXP/tunneling/la_lin.tar.gz"
    [ -f "$EXP/tunneling/la_lin.tar.gz" ] && tar xf "$EXP/tunneling/la_lin.tar.gz" -C "$EXP/tunneling" 2>/dev/null && rm -f "$EXP/tunneling/la_lin.tar.gz"
fi

log_info "Webshells..."
echo '<?php system($_GET["cmd"]); ?>' > "$WEB/cmd.php"
safe_download "https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php" "$WEB/php-reverse-shell.php"
cp /usr/share/webshells/aspx/cmdasp.aspx "$WEB/" 2>/dev/null

log_info "Exploits por servicio..."
safe_clone "https://github.com/3ndG4me/AutoBlue-MS17-010.git" "$EXP/smb/AutoBlue-MS17-010"
safe_download "https://raw.githubusercontent.com/dreadlocked/Drupalgeddon2/master/drupalgeddon2.rb" "$EXP/web/drupalgeddon2.rb"
safe_clone "https://github.com/kozmer/log4j-shell-poc.git" "$EXP/web/log4j-shell-poc"
safe_clone "https://github.com/ly4k/PwnKit.git" "$EXP/linux-privesc/PwnKit"
log_ok "AD + Tunneling + Exploits descargados"

# ══════════════════════════════════════════════════════════════════════════════
log_step "FASE 10/10: Symlinks www/"
cd "$WWW"
for f in "$LIN"/{linpeas.sh,pspy64,LinEnum.sh,lse.sh}; do ln -sf "$f" . 2>/dev/null; done
for f in "$WIN"/{winPEASany.exe,GodPotato-NET4.exe,PrintSpoofer64.exe,nc.exe,PowerView.ps1,PowerUp.ps1,FullPowers.exe}; do ln -sf "$f" . 2>/dev/null; done
for f in "$AD"/{Rubeus.exe,Certify.exe,kerbrute}; do ln -sf "$f" . 2>/dev/null; done
[ -f "$AD/mimikatz/x64/mimikatz.exe" ] && ln -sf "$AD/mimikatz/x64/mimikatz.exe" . 2>/dev/null
[ -f "$WIN/RunasCs/RunasCs.exe" ] && ln -sf "$WIN/RunasCs/RunasCs.exe" . 2>/dev/null
[ -f "$EXP/tunneling/chisel_linux" ] && ln -sf "$EXP/tunneling/chisel_linux" chisel 2>/dev/null
[ -f "$EXP/tunneling/chisel_win" ] && ln -sf "$EXP/tunneling/chisel_win" chisel.exe 2>/dev/null
ln -sf "$WEB/cmd.php" . 2>/dev/null
log_ok "www/ listo"

# ══════════════════════════════════════════════════════════════════════════════
TOTAL=$(find "$TOOLS" -type f 2>/dev/null | wc -l)
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}${BOLD}Instalación completada — $TOTAL archivos en ~/oscp-tools${NC}     ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Atajos de teclado:${NC}"
echo -e "  super+Enter              Terminal"
echo -e "  super+w                  Cerrar ventana"
echo -e "  super+d                  Rofi"
echo -e "  super+1-9                Escritorios"
echo -e "  super+shift+1-9          Mover ventana a escritorio"
echo -e "  super+alt+flechas        Agrandar ventana"
echo -e "  super+alt+shift+flechas  Encoger ventana"
echo -e "  super+ctrl+flechas       Mover/swap ventana"
echo -e "  super+hold+click         Mover con ratón"
echo -e "  super+click derecho      Redimensionar con ratón"
echo -e "  ctrl+shift+t             Nueva pestaña terminal"
echo -e "  ctrl+shift+alt+t         Renombrar pestaña"
echo -e "  ctrl+shift+w             Cerrar pestaña"
echo -e "  Print                    Screenshot (flameshot)"
echo ""
echo -e "${BOLD}Atajos OSCP:${NC}"
echo -e "  super+shift+i            Copiar IP tun0"
echo -e "  super+shift+s            HTTP server"
echo -e "  super+shift+n            Listener nc :4444"
echo -e "  super+shift+t            Terminal en ~/oscp-tools"
echo -e "  super+shift+c            Buscar cheatsheet (rofi)"
echo -e "  super+shift+e            Cronómetro examen start/stop"
echo -e "  super+shift+alt+e        Cronómetro examen reset"
echo -e "  super+shift+h            Hackspace (tmux layout)"
echo -e "  super+shift+v            Clipboard sync status"
echo -e "  super+shift+Return       Terminal root"
echo -e "  super+shift+f            Firefox"
echo -e "  super+shift+b            Burp Suite"
echo -e "  super+x                  Power menu"
echo ""
echo -e "${BOLD}Scripts OSCP:${NC}"
echo -e "  settarget <IP> [nombre]  Setear target (polybar)"
echo -e "  settarget                Limpiar target"
echo -e "  autorecon <IP>           Nmap TCP+UDP+vuln automático"
echo -e "  scopegen examen          Crear dirs para examen OSCP"
echo -e "  scopegen lab <nombre>    Crear dirs para máquina"
echo -e "  portfwd                  Helper túneles chisel/ligolo/ssh"
echo -e "  vpnconnect htb|offsec    Conectar VPN rápido"
echo -e "  vpnconnect stop          Desconectar VPN"
echo -e "  hackspace                Tmux layout de hacking"
echo -e "  nj <comando>             Notifica al terminar (nj nmap ...)"
echo -e "  extractports <file>      Extraer puertos de nmap"
echo -e "  serve                    HTTP server en ~/oscp-tools/www"
echo ""
echo -e "${BOLD}Tmux (prefix: Ctrl+a):${NC}"
echo -e "  Ctrl+a |                 Split vertical"
echo -e "  Ctrl+a -                 Split horizontal"
echo -e "  Alt+flechas              Navegar paneles"
echo -e "  Ctrl+a c                 Nueva ventana"
echo -e "  Ctrl+a r                 Recargar config"
echo ""
echo -e "${BOLD}Próximos pasos:${NC}"
echo -e "  1. ${CYAN}sudo reboot${NC}"
echo -e "  2. Seleccionar ${CYAN}bspwm${NC} en el login manager"
echo -e "  3. ${CYAN}super + Enter${NC} para terminal"
echo -e "  4. Guardar .ovpn en ${CYAN}~/vpn/${NC} para usar vpnconnect"
echo -e "  5. Firefox: ${CYAN}Ctrl+Shift+O → Importar HTML → ~/oscp-bookmarks.html${NC}"
echo ""

read -p "¿Reiniciar ahora? [s/N] " -n 1 -r
echo
[[ $REPLY =~ ^[SsYy]$ ]] && sudo reboot
