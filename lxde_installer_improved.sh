#!/bin/bash

################################################################################
# Script mejorado para instalar/desinstalar LXDE en Orange Pi Zero 3
# Opciones: LXDE Full o LXDE Core (mínima)
################################################################################

set -e  # Salir en caso de error
set -u  # Error en variables no definidas

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
LOG_FILE="/tmp/lxde_installer_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.lxde_backup_$(date +%Y%m%d_%H%M%S)"
INTERACTIVE=1
INSTALL_TYPE=""

################################################################################
# Funciones de utilidad
################################################################################

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    log "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    clear
    log "${CYAN}=========================================="
    log "   LXDE Installer para Orange Pi Zero 3"
    log "==========================================${NC}"
    log ""
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutes este script como root. Usa tu usuario normal."
        exit 1
    fi
}

check_sudo() {
    if ! sudo -v; then
        log_error "Se requieren permisos sudo para ejecutar este script."
        exit 1
    fi
    # Mantener sudo activo
    while true; do sudo -n true; sleep 60; kill -0 "$${$}| exit; done 2>/dev/null &
}

check_disk_space() {
    local required_mb=$1
    local available_mb=$(df / | tail -1 | awk '{print int($4/1024)}')
    
    log_info "Espacio disponible: ${available_mb}MB"
    log_info "Espacio requerido: ${required_mb}MB"
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log_error "No hay suficiente espacio en disco."
        log_error "Requerido: ${required_mb}MB, Disponible: ${available_mb}MB"
        exit 1
    fi
    
    log_success "Espacio en disco suficiente."
}

check_existing_de() {
    log_info "Verificando entornos de escritorio existentes..."
    
    local existing_de=()
    
    command -v gnome-session &>/dev/null && existing_de+=("GNOME")
    command -v startxfce4 &>/dev/null && existing_de+=("XFCE")
    command -v startkde &>/dev/null && existing_de+=("KDE")
    command -v startlxde &>/dev/null && existing_de+=("LXDE")
    
    if [ ${#existing_de[@]} -gt 0 ]; then
        log_warning "Se detectaron los siguientes entornos de escritorio:"
        for de in "${existing_de[@]}"; do
            log_warning "  - $de"
        done
        
        if [ $INTERACTIVE -eq 1 ]; then
            read -r -p "¿Deseas continuar de todas formas? (s/n): " response
            if [[ ! "$response" =~ ^[Ss]$ ]]; then
                log_info "Instalación cancelada."
                exit 0
            fi
        fi
    else
        log_success "No se detectaron otros entornos de escritorio."
    fi
}

create_backup() {
    log_info "Creando backup de configuraciones existentes..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup de configuraciones de usuario
    [ -d ~/.config/lxsession ] && cp -r ~/.config/lxsession "$BACKUP_DIR/" 2>/dev/null || true
    [ -d ~/.config/openbox ] && cp -r ~/.config/openbox "$BACKUP_DIR/" 2>/dev/null || true
    [ -f ~/.dmrc ] && cp ~/.dmrc "$BACKUP_DIR/" 2>/dev/null || true
    
    log_success "Backup creado en: $BACKUP_DIR"
}

################################################################################
# Funciones de instalación
################################################################################

show_install_menu() {
    log ""
    log "${CYAN}Selecciona el tipo de instalación:${NC}"
    log ""
    log "${GREEN}1)${NC} LXDE Core (Mínima) ${YELLOW}~200-300MB${NC}"
    log "   - Entorno de escritorio básico"
    log "   - Gestor de archivos PCManFM"
    log "   - Terminal LXTerminal"
    log "   - Editor de texto Leafpad"
    log "   - Ideal para dispositivos con recursos limitados"
    log ""
    log "${GREEN}2)${NC} LXDE Full (Completa) ${YELLOW}~500-700MB${NC}"
    log "   - Todo lo de LXDE Core"
    log "   - Navegador web"
    log "   - Suite de aplicaciones multimedia"
    log "   - Herramientas de sistema adicionales"
    log "   - Juegos y accesorios"
    log ""
    log "${GREEN}3)${NC} Cancelar"
    log ""
}

install_lxde_core() {
    log_info "Instalando LXDE Core (mínima)..."
    
    check_disk_space 300
    
    log_info "Actualizando lista de paquetes..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    
    log_info "Instalando Xorg..."
    if sudo apt install -y xorg 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Xorg instalado."
    else
        log_error "Error al instalar Xorg."
        return 1
    fi
    
    log_info "Instalando LightDM..."
    if sudo apt install -y lightdm lightdm-gtk-greeter 2>&1 | tee -a "$LOG_FILE"; then
        log_success "LightDM instalado."
    else
        log_error "Error al instalar LightDM."
        return 1
    fi
    
    log_info "Instalando LXDE Core..."
    if sudo apt install -y lxde-core 2>&1 | tee -a "$LOG_FILE"; then
        log_success "LXDE Core instalado."
    else
        log_error "Error al instalar LXDE Core."
        return 1
    fi
    
    # Aplicaciones esenciales adicionales
    log_info "Instalando aplicaciones esenciales..."
    sudo apt install -y \
        lxterminal \
        pcmanfm \
        leafpad \
        lxappearance \
        2>&1 | tee -a "$LOG_FILE"
    
    log_success "Instalación de LXDE Core completada."
}

install_lxde_full() {
    log_info "Instalando LXDE Full (completa)..."
    
    check_disk_space 700
    
    log_info "Actualizando lista de paquetes..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    
    log_info "Instalando Xorg..."
    if sudo apt install -y xorg 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Xorg instalado."
    else
        log_error "Error al instalar Xorg."
        return 1
    fi
    
    log_info "Instalando LightDM..."
    if sudo apt install -y lightdm lightdm-gtk-greeter 2>&1 | tee -a "$LOG_FILE"; then
        log_success "LightDM instalado."
    else
        log_error "Error al instalar LightDM."
        return 1
    fi
    
    log_info "Instalando LXDE Full..."
    if sudo apt install -y lxde 2>&1 | tee -a "$LOG_FILE"; then
        log_success "LXDE Full instalado."
    else
        log_error "Error al instalar LXDE Full."
        return 1
    fi
    
    log_success "Instalación de LXDE Full completada."
}

configure_lightdm() {
    log_info "Configurando LightDM como gestor de pantalla predeterminado..."
    
    # Configurar LightDM como default
    if sudo systemctl enable lightdm 2>&1 | tee -a "$LOG_FILE"; then
        log_success "LightDM configurado como gestor predeterminado."
    else
        log_warning "No se pudo configurar LightDM automáticamente."
    fi
    
    # Crear configuración básica si no existe
    if [ ! -f /etc/lightdm/lightdm.conf ]; then
        log_info "Creando configuración de LightDM..."
        sudo bash -c 'cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=LXDE
autologin-user=
autologin-user-timeout=0
EOF'
        log_success "Configuración de LightDM creada."
    fi
}

verify_installation() {
    log_info "Verificando instalación..."
    
    local errors=0
    
    if ! command -v startlxde &>/dev/null; then
        log_error "LXDE no se instaló correctamente."
        errors=$((errors + 1))
    else
        log_success "LXDE instalado correctamente."
    fi
    
    if ! command -v lightdm &>/dev/null; then
        log_error "LightDM no se instaló correctamente."
        errors=$((errors + 1))
    else
        log_success "LightDM instalado correctamente."
    fi
    
    if ! command -v startx &>/dev/null; then
        log_error "Xorg no se instaló correctamente."
        errors=$((errors + 1))
    else
        log_success "Xorg instalado correctamente."
    fi
    
    return $errors
}

################################################################################
# Funciones de desinstalación
################################################################################

uninstall_lxde() {
    log_warning "¡ADVERTENCIA! Esta acción eliminará LXDE y todas sus configuraciones."
    
    if [ $INTERACTIVE -eq 1 ]; then
        read -r -p "¿Estás seguro de que deseas continuar? (escribe 'SI' en mayúsculas): " response
        if [ "$response" != "SI" ]; then
            log_info "Desinstalación cancelada."
            return 0
        fi
    fi
    
    create_backup
    
    log_info "Desinstalando LXDE, Xorg y LightDM..."
    
    if sudo apt purge -y lxde lxde-core lxde-common lightdm lightdm-gtk-greeter xorg 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Paquetes eliminados."
    else
        log_error "Error al eliminar algunos paquetes."
    fi
    
    log_info "Limpiando paquetes huérfanos..."
    sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
    sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
    
    # Limpiar configuraciones de usuario (opcional)
    if [ $INTERACTIVE -eq 1 ]; then
        read -r -p "¿Deseas eliminar también las configuraciones de usuario? (s/n): " response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            rm -rf ~/.config/lxsession
            rm -rf ~/.config/openbox
            rm -rf ~/.config/pcmanfm
            rm -f ~/.dmrc
            log_success "Configuraciones de usuario eliminadas."
        fi
    fi
    
    log_success "Desinstalación completada."
}

################################################################################
# Funciones de información
################################################################################

show_final_info() {
    log ""
    log_success "=========================================="
    log_success "   Instalación completada exitosamente"
    log_success "=========================================="
    log ""
    log_info "Tipo de instalación: $INSTALL_TYPE"
    log_info "Log guardado en: $LOG_FILE"
    
    if [ -d "$BACKUP_DIR" ]; then
        log_info "Backup guardado en: $BACKUP_DIR"
    fi
    
    log ""
    log_warning "⚠️  IMPORTANTE: Debes reiniciar el sistema para usar el entorno gráfico."
    log ""
    log_info "Para iniciar LXDE después del reinicio:"
    log_info "  - El sistema iniciará automáticamente en modo gráfico"
    log_info "  - O ejecuta manualmente: startx"
    log ""
    log_info "Comandos útiles:"
    log_info "  - Reiniciar ahora: sudo reboot"
    log_info "  - Ver logs: cat $LOG_FILE"
    log_info "  - Cambiar tema: lxappearance"
    log ""
    
    if [ $INTERACTIVE -eq 1 ]; then
        read -r -p "¿Deseas reiniciar ahora? (s/n): " response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            log_info "Reiniciando sistema..."
            sudo reboot
        fi
    fi
}

################################################################################
# Menú principal
################################################################################

show_main_menu() {
    print_header
    
    log "${CYAN}Selecciona una opción:${NC}"
    log ""
    log "${GREEN}1)${NC} Instalar LXDE"
    log "${GREEN}2)${NC} Desinstalar LXDE"
    log "${GREEN}3)${NC} Verificar instalación existente"
    log "${GREEN}4)${NC} Salir"
    log ""
}

main() {
    print_header
    
    # Verificaciones iniciales
    check_root
    check_sudo
    
    if [ $INTERACTIVE -eq 1 ]; then
        show_main_menu
        read -r -p "Opción: " main_option
        
        case $main_option in
            1)
                check_existing_de
                show_install_menu
                read -r -p "Opción: " install_option
                
                case $install_option in
                    1)
                        INSTALL_TYPE="LXDE Core"
                        install_lxde_core
                        configure_lightdm
                        verify_installation
                        show_final_info
                        ;;
                    2)
                        INSTALL_TYPE="LXDE Full"
                        install_lxde_full
                        configure_lightdm
                        verify_installation
                        show_final_info
                        ;;
                    3)
                        log_info "Instalación cancelada."
                        exit 0
                        ;;
                    *)
                        log_error "Opción inválida."
                        exit 1
                        ;;
                esac
                ;;
            2)
                uninstall_lxde
                ;; 
            3)
                verify_installation
                ;;
            4)
                log_info "Saliendo..."
                exit 0
                ;;
            *)
                log_error "Opción inválida."
                exit 1
                ;;
        esac
    else
        # Modo no interactivo
        if [ -z "${1:-}" ]; then
            log_error "En modo no interactivo debes especificar: install-core, install-full o uninstall"
            exit 1
        fi
        
        case $1 in
            install-core)
                INSTALL_TYPE="LXDE Core"
                install_lxde_core
                configure_lightdm
                verify_installation
                ;;
            install-full)
                INSTALL_TYPE="LXDE Full"
                install_lxde_full
                configure_lightdm
                verify_installation
                ;;
            uninstall)
                uninstall_lxde
                ;;
            *)
                log_error "Opción inválida: $1"
                exit 1
                ;;
        esac
    fi
}

# Procesar argumentos
while getopts "nh" opt; do
    case $opt in
        n)
            INTERACTIVE=0
            ;;
        h)
            echo "Uso: $0 [-n] [-h] [install-core|install-full|uninstall]"
            echo ""
            echo "Opciones:"
            echo "  -n                Modo no interactivo"
            echo "  -h                Mostrar esta ayuda"
            echo ""
            echo "Comandos (solo en modo no interactivo):"
            echo "  install-core      Instalar LXDE Core (mínima)"
            echo "  install-full      Instalar LXDE Full (completa)"
            echo "  uninstall         Desinstalar LXDE"
            echo ""
            echo "Ejemplos:"
            echo "  $0                         # Modo interactivo"
            echo "  $0 -n install-core         # Instalar Core sin interacción"
            echo "  $0 -n install-full         # Instalar Full sin interacción"
            exit 0
            ;;
        \?)
            echo "Opción inválida: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))

# Ejecutar
main "$@"
