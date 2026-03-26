# AutoBSPWM-OSCP

Entorno BSPWM completo optimizado para el examen OSCP y sesiones de pentesting en Kali Linux. Un solo script instala y configura todo: window manager, herramientas, scripts de automatización y un workflow pensado para maximizar eficiencia durante el examen.

## Qué incluye

**Window Manager y UI**
- BSPWM + SXHKD compilados desde source
- Polybar con módulos OSCP: target activo, estado VPN (detecta HTB/OffSec/OSCP), cronómetro de examen, IP de interfaz
- Kitty terminal con Hack Nerd Font
- Picom, Dunst (notificaciones), Rofi (launcher + cheatsheet)
- Paleta de colores gris/blanco consistente en todo el entorno
- Clipboard bidireccional host ↔ VM (VMware, VirtualBox, QEMU/KVM)

**ZSH**
- Oh My Zsh + Powerlevel10k (usuario + root)
- Plugins: autosuggestions, syntax-highlighting, completions
- Aliases para nmap, smbclient, http server, navigation rápida
- Funciones: `settarget`, `mkmachine`, `initscan`, `extractports`

**Tmux**
- Prefix `Ctrl+a`, splits intuitivos (`|` y `-`)
- Navegación con Alt+flechas y vim keys
- Copy mode con vi keys → xclip

**Scripts OSCP**
| Script | Descripción |
|--------|-------------|
| `autorecon` | Nmap automatizado: TCP rápido → extrae puertos → detallado → UDP → vuln scan |
| `scopegen` | Genera estructura de directorios para examen (`scopegen examen`) o labs (`scopegen lab <nombre>`) |
| `portfwd` | Helper interactivo para túneles: Chisel, Ligolo-ng, SSH (local/dynamic/remote) |
| `vpnconnect` | Conexión rápida a HTB, OffSec o cualquier .ovpn |
| `hackspace` | Layout tmux de 3 paneles: trabajo, listener, notas |
| `settarget` | Setea IP/nombre del target (se muestra en polybar) |
| `notify-job` | Wrapper que notifica cuando un comando largo termina |
| `rofi-cheatsheet` | Busca en cheatsheet con rofi y copia el comando al clipboard |
| `clipboard-sync` | Daemon de clipboard bidireccional host ↔ VM |
| `exam_timer` | Cronómetro start/stop/reset para el examen (integrado en polybar) |

**Herramientas pre-descargadas** (`~/oscp-tools/`)
- Linux: linpeas, pspy64, LinEnum, lse, linux-exploit-suggester
- Windows: winPEAS, PowerView, PowerUp, Seatbelt, GodPotato, PrintSpoofer, JuicyPotato, RunasCs, FullPowers, nc.exe
- AD: Rubeus, Certify, kerbrute, mimikatz, PetitPotam, noPac, PKINITtools
- Tunneling: Chisel (linux + windows), Ligolo-ng (proxy + agent)
- Webshells: cmd.php, php-reverse-shell, cmdasp.aspx
- Exploits: AutoBlue (MS17-010), Drupalgeddon2, Log4Shell, PwnKit
- `~/oscp-tools/www/` con symlinks a todo para transfer rápido con `serve`

**Extras**
- Firefox bookmarks OSCP organizados (HackTricks, GTFOBins, RevShells, PayloadsAllTheThings, etc.)
- Proxychains4 preconfigurado (socks5 127.0.0.1:1080)
- Cheatsheet con ~70 comandos searchable vía rofi

## Requisitos

- Kali Linux (probado en 2024.x / 2025.x)
- Ejecución en VM (VMware, VirtualBox o QEMU/KVM)
- Conexión a internet (para descargar herramientas)
- ~2GB de espacio libre

## Instalación

```bash
git clone https://github.com/GorosX/AutoBspwm.git
cd AutoBspwm
chmod +x setup.sh
./setup.sh
```

> **No ejecutar como root.** El script pide `sudo` cuando lo necesita.

Después de la instalación:
1. Reiniciar
2. Seleccionar **bspwm** en el login manager
3. `super + Enter` para abrir terminal
4. Guardar archivos `.ovpn` en `~/vpn/` para usar `vpnconnect`
5. Importar bookmarks en Firefox: `Ctrl+Shift+O` → Importar HTML → `~/oscp-bookmarks.html`

## Keybindings principales

### Generales
| Atajo | Acción |
|-------|--------|
| `super + Enter` | Terminal |
| `super + d` | Rofi launcher |
| `super + w` | Cerrar ventana |
| `super + 1-9` | Cambiar escritorio |
| `super + shift + 1-9` | Mover ventana a escritorio |
| `super + f` | Fullscreen |
| `super + space` | Toggle floating |
| `super + alt + flechas` | Agrandar ventana |
| `super + alt + shift + flechas` | Encoger ventana |
| `super + ctrl + flechas` | Swap ventana |
| `Print` | Screenshot (flameshot) |
| `super + x` | Power menu |

### OSCP
| Atajo | Acción |
|-------|--------|
| `super + shift + i` | Copiar IP tun0 |
| `super + shift + s` | HTTP server en www/ |
| `super + shift + n` | Listener nc :4444 |
| `super + shift + c` | Buscar cheatsheet |
| `super + shift + e` | Exam timer start/stop |
| `super + shift + alt + e` | Exam timer reset |
| `super + shift + h` | Hackspace (tmux layout) |
| `super + shift + v` | Clipboard sync status |
| `super + shift + t` | Terminal en ~/oscp-tools |
| `super + shift + Return` | Terminal root |
| `super + shift + f` | Firefox |
| `super + shift + b` | Burp Suite |

### Tmux (prefix: `Ctrl+a`)
| Atajo | Acción |
|-------|--------|
| `Ctrl+a \|` | Split vertical |
| `Ctrl+a -` | Split horizontal |
| `Alt + flechas` | Navegar paneles |
| `Ctrl+a c` | Nueva ventana |
| `Ctrl+a r` | Recargar config |

## Clipboard bidireccional

El entorno incluye un daemon (`clipboard-sync`) que sincroniza el clipboard entre el host y la VM automáticamente. Soporta:

- **VMware**: Detecta e inicia `vmware-user` / `vmtoolsd` (requiere `open-vm-tools-desktop`)
- **VirtualBox**: Lanza `VBoxClient --clipboard` (requiere Guest Additions)
- **QEMU/KVM**: Inicia `spice-vdagent`

Además, mantiene sincronizados los buffers PRIMARY (selección con ratón) y CLIPBOARD (Ctrl+C/V), algo que X11 no hace por defecto y que causa confusión constante durante pentesting.

Se inicia automáticamente con bspwm. Para verificar:
```bash
clipboard-sync status
# o con el atajo: super + shift + v
```

## Estructura del proyecto

```
autobspwm-oscp/
├── setup.sh                    # Instalador principal (10 fases)
├── config/
│   ├── bspwm/bspwmrc           # Configuración bspwm + autostart
│   ├── sxhkd/sxhkdrc           # Keybindings
│   ├── polybar/                 # Barra superior
│   │   ├── config.ini
│   │   ├── launch.sh
│   │   └── scripts/             # target, vpn, exam timer, ethernet
│   ├── kitty/kitty.conf
│   ├── picom/picom.conf
│   ├── dunst/dunstrc
│   └── firefox/bookmarks.html
├── scripts/
│   ├── autorecon.sh
│   ├── scopegen.sh
│   ├── portfwd.sh
│   ├── vpnconnect.sh
│   ├── hackspace.sh
│   ├── settarget.sh
│   ├── notify-job.sh
│   ├── clipboard-sync.sh
│   ├── rofi-cheatsheet.sh
│   ├── rofi-powermenu.sh
│   └── cheatsheet.txt
├── .zshrc
├── .tmux.conf
└── .p10k.zsh
```

## Personalización

- **Wallpaper**: Coloca cualquier imagen como `wallpapers/wallpaper.jpg` en el directorio del proyecto antes de instalar, o después en `~/.config/bspwm/wallpaper.jpg`
- **Cheatsheet**: Edita `~/Scripts/cheatsheet.txt` con formato `descripción | comando`
- **VPN**: Guarda los `.ovpn` en `~/vpn/` con nombres que contengan `htb`/`hackthebox` u `offsec`/`pen-200`
- **Target**: `settarget 10.10.10.5 MiMáquina` lo muestra en polybar

## Screenshots

### Entorno completo

Vista general del escritorio con BSPWM: polybar mostrando el target activo, exam timer y estado VPN. A la izquierda `scopegen examen` generando la estructura de directorios del examen OSCP con `tree`. Arriba a la derecha `portfwd` con el menú interactivo de túneles. Abajo `settarget` seteando el target en polybar y `fastfetch` con la info del sistema.

![desktop](<img width="1919" height="1079" alt="imagen" src="https://github.com/user-attachments/assets/92fa5daa-b65a-46eb-b0e3-eb3b454cbd15" />
)

## License

MIT License — usa, modifica y comparte libremente.

## Contribuir

PRs bienvenidos. Si encuentras un bug o tienes una idea para mejorar el workflow, abre un issue.
