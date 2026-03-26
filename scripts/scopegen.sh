#!/bin/bash
# scopegen — Genera estructura de directorios para un examen OSCP o sesión de labs
# Uso: scopegen examen          → crea estructura de examen (3 standalone + 1 AD set)
#      scopegen lab <nombre>    → crea estructura para una máquina de lab

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${CYAN}scopegen${NC} — Generador de estructura OSCP"
    echo ""
    echo "Uso:"
    echo "  scopegen examen              Estructura completa de examen"
    echo "  scopegen lab <nombre>        Estructura para una máquina"
    echo "  scopegen lab <nombre> <IP>   Estructura + settarget automático"
    exit 0
fi

case "$1" in
    examen|exam)
        FECHA=$(date +%Y-%m-%d)
        DIR="OSCP-Exam-$FECHA"
        mkdir -p "$DIR"/{Standalone-1,Standalone-2,Standalone-3}/{scans,loot,exploits,screenshots}
        mkdir -p "$DIR"/AD-Set/{DC,MS01,MS02}/{scans,loot,exploits,screenshots}
        mkdir -p "$DIR"/AD-Set/bloodhound
        mkdir -p "$DIR"/Report

        cat > "$DIR/notas.md" << 'NOTAS'
# OSCP Exam Notes
## Credenciales Encontradas
| Usuario | Password/Hash | Servicio | Máquina |
|---------|--------------|----------|---------|
|         |              |          |         |

## Flags
| Máquina | local.txt | proof.txt |
|---------|-----------|-----------|
| Standalone-1 | | |
| Standalone-2 | | |
| Standalone-3 | | |
| AD - DC | | |
| AD - MS01 | | |
| AD - MS02 | | |

## Timeline
- HH:MM — Inicio examen
- HH:MM —
NOTAS

        cat > "$DIR/Report/report-checklist.md" << 'REPORT'
# Report Checklist
- [ ] Cada máquina tiene: whoami + hostname + ip + flag screenshot
- [ ] Pasos de reproducción detallados con comandos exactos
- [ ] Screenshots de cada paso importante
- [ ] Recomendaciones de remediación por vulnerabilidad
- [ ] PDF generado y verificado
- [ ] Empaquetado en .7z: OSCP-OS-XXXXX-Exam-Report.7z
- [ ] Subido a https://upload.offsec.com
REPORT

        echo -e "${GREEN}[✔]${NC} Estructura de examen creada en ${CYAN}$DIR/${NC}"
        echo "    ├── Standalone-1/  Standalone-2/  Standalone-3/"
        echo "    ├── AD-Set/ (DC, MS01, MS02, bloodhound)"
        echo "    ├── Report/"
        echo "    └── notas.md"
        cd "$DIR"
        ;;

    lab)
        NAME="$2"
        IP="$3"
        if [ -z "$NAME" ]; then
            echo -e "${RED}[!]${NC} Uso: scopegen lab <nombre> [IP]"
            exit 1
        fi
        mkdir -p "$NAME"/{scans,loot,exploits,screenshots}

        cat > "$NAME/notas.md" << EOF
# $NAME
**IP**: ${IP:-pendiente}
**OS**:
**Dificultad**:

## Credenciales
| Usuario | Password/Hash | Servicio |
|---------|--------------|----------|
|         |              |          |

## Flags
- user.txt:
- root.txt:

## Notas
-
EOF

        echo -e "${GREEN}[✔]${NC} Estructura creada para ${CYAN}$NAME${NC}"
        if [ -n "$IP" ]; then
            echo "$IP $NAME" > /tmp/.target
            echo -e "${GREEN}[✔]${NC} Target seteado: $IP $NAME"
        fi
        cd "$NAME"
        ;;

    *)
        echo -e "${RED}[!]${NC} Opción no reconocida: $1"
        echo "Uso: scopegen examen | scopegen lab <nombre> [IP]"
        exit 1
        ;;
esac
