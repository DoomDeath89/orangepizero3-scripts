#!/bin/bash

################################################################################
# Script mejorado para configurar audio ALSA puro (HDMI) en Orange Pi Zero 3
# Desactiva PulseAudio/PipeWire y configura ALSA con mejor manejo de errores
################################################################################

set -e  # Salir en caso de error
set -u  # Error en variables no definidas

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Archivos y directorios
ASOUND_FILE="$HOME/.asoundrc"
BACKUP_DIR="$HOME/.audio_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/tmp/audio_setup_$(date +%Y%m%d_%H%M%S).log"

# Variables globales
INTERACTIVE=1
HDMI_CARD=""

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

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutes este script como root. Usa tu usuario normal (el script pedirá sudo cuando sea necesario)."
        exit 1
    fi
}

check_sudo() {
    if ! sudo -v; then
        log_error "Se requieren permisos sudo para ejecutar este script."
        exit 1
    fi
    # Mantener sudo activo
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

check_dependencies() {
    log_info "Verificando dependencias..."
    local missing_deps=()
    
    for cmd in aplay amixer speaker-test; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "Faltan dependencias: ${missing_deps[*]}"
        log_info "Instalando alsa-utils..."
        sudo apt update
        sudo apt install -y alsa-utils
        log_success "Dependencias instaladas."
    else
        log_success "Todas las dependencias están instaladas."
    fi
}

create_backup() {
    log_info "Creando backup de configuraciones existentes..."
    mkdir -p "$BACKUP_DIR"
    
    if [ -f "$ASOUND_FILE" ]; then
        cp "$ASOUND_FILE" "$BACKUP_DIR/"
        log_success "Backup de .asoundrc creado en: $BACKUP_DIR"
    fi
    
    if [ -d ~/.config/pulse ]; then
        cp -r ~/.config/pulse "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    if [ -d ~/.config/pipewire ]; then
        cp -r ~/.config/pipewire "$BACKUP_DIR/" 2>/dev/null || true
    fi
}

################################################################################
# Funciones principales
################################################################################

remove_pulseaudio() {
    log_info "Verificando si PulseAudio está instalado..."
    
    if command -v pulseaudio >/dev/null 2>&1; then
        log_warning "PulseAudio detectado. Procediendo a eliminar..."
        
        # Detener servicios
        systemctl --user stop pulseaudio.socket pulseaudio.service 2>/dev/null || true
        systemctl --user disable pulseaudio.socket pulseaudio.service 2>/dev/null || true
        systemctl --user mask pulseaudio.socket pulseaudio.service 2>/dev/null || true
        
        # Eliminar paquetes
        if sudo apt remove --purge -y pulseaudio pulseaudio-utils; then
            sudo apt autoremove -y
            rm -rf ~/.config/pulse
            log_success "PulseAudio eliminado correctamente."
        else
            log_error "Error al eliminar PulseAudio."
            return 1
        fi
    else
        log_success "PulseAudio no está instalado."
    fi
}

remove_pipewire() {
    log_info "Verificando si PipeWire está instalado..."
    
    if command -v pipewire >/dev/null 2>&1; then
        log_warning "PipeWire detectado. Procediendo a eliminar..."
        
        # Detener servicios
        systemctl --user stop pipewire pipewire-pulse pipewire.socket 2>/dev/null || true
        systemctl --user disable pipewire pipewire-pulse pipewire.socket 2>/dev/null || true
        systemctl --user mask pipewire pipewire-pulse pipewire.socket 2>/dev/null || true
        
        # Eliminar paquetes
        if sudo apt remove --purge -y pipewire pipewire-audio-client-libraries libpipewire* wireplumber pipewire-pulse; then
            sudo apt autoremove -y
            rm -rf ~/.config/pipewire
            log_success "PipeWire eliminado correctamente."
        else
            log_error "Error al eliminar PipeWire."
            return 1
        fi
    else
        log_success "PipeWire no está instalado."
    fi
}

add_user_to_audio_group() {
    log_info "Verificando pertenencia al grupo 'audio'..."
    
    if groups "$USER" | grep -q "\baudio\b"; then
        log_success "El usuario ya pertenece al grupo 'audio'."
    else
        log_info "Agregando usuario al grupo 'audio'..."
        if sudo usermod -aG audio "$USER"; then
            log_success "Usuario agregado al grupo 'audio'."
            log_warning "Necesitarás cerrar sesión y volver a entrar para que el cambio tome efecto."
        else
            log_error "Error al agregar usuario al grupo audio."
            return 1
        fi
    fi
}

detect_hdmi_card() {
    log_info "Detectando tarjeta HDMI..."
    
    # Mostrar todas las tarjetas disponibles
    log_info "Tarjetas de audio disponibles:"
    aplay -l | tee -a "$LOG_FILE"
    
    # Intentar detectar HDMI
    HDMI_CARD=$(aplay -l | grep -i "HDMI" | head -n1 | awk -F: '{print $1}' | awk '{print $2}')
    
    if [ -z "$HDMI_CARD" ]; then
        log_error "No se detectó salida HDMI automáticamente."
        
        if [ $INTERACTIVE -eq 1 ]; then
            log_info "Por favor, ingresa el número de tarjeta HDMI manualmente:"
            read -r -p "Número de tarjeta: " HDMI_CARD
            
            if [ -z "$HDMI_CARD" ]; then
                log_error "Número de tarjeta no válido."
                exit 1
            fi
        else
            log_error "Ejecuta 'aplay -l' para ver las tarjetas disponibles."
            exit 1
        fi
    fi
    
    log_success "HDMI detectado como tarjeta $HDMI_CARD"
}

generate_asoundrc() {
    log_info "Generando archivo .asoundrc con HDMI card $HDMI_CARD..."
    
    cat > "$ASOUND_FILE" << EOF
# Configuración ALSA para Orange Pi Zero 3 - Salida HDMI
# Generado por audio_setup_improved.sh el $(date)

pcm.!default {
    type plug
    slave.pcm "hdmi_dmix"
}

pcm.hdmi_dmix {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:$HDMI_CARD,0"
        rate 48000
        format S16_LE
        period_size 512
        buffer_size 2048
    }
    bindings {
        0 0
        1 1
    }
}

ctl.!default {
    type hw
    card $HDMI_CARD
}

# Configuración adicional para mejor compatibilidad
pcm.hdmi_hw {
    type hw
    card $HDMI_CARD
    device 0
}

pcm.hdmi_plughw {
    type plug
    slave.pcm "hdmi_hw"
}
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Archivo .asoundrc configurado exitosamente en: $ASOUND_FILE"
        chmod 644 "$ASOUND_FILE"
    else
        log_error "Error al crear el archivo .asoundrc"
        return 1
    fi
}

test_audio() {
    log_info "Realizando prueba de audio..."
    log_warning "Deberías escuchar un sonido de prueba por HDMI ahora..."
    
    if speaker-test -D default -c 2 -t wav -l 1 2>&1 | tee -a "$LOG_FILE"; then
        log_success "Prueba de audio completada."
        
        if [ $INTERACTIVE -eq 1 ]; then
            read -r -p "¿Escuchaste el sonido de prueba? (s/n): " response
            if [[ "$response" =~ ^[Ss]$ ]]; then
                log_success "¡Audio funcionando correctamente!"
            else
                log_warning "Si no escuchaste nada, verifica:"
                log_warning "1. El cable HDMI está conectado correctamente"
                log_warning "2. El volumen del TV/monitor no está en mudo"
                log_warning "3. Ejecuta 'alsamixer' para verificar niveles de volumen"
            fi
        fi
    else
        log_error "Error en la prueba de audio."
        log_info "Intenta ejecutar manualmente: speaker-test -D default -c 2 -t wav"
        return 1
    fi
}

show_final_info() {
    log_success "\n=========================================="
    log_success "Configuración de audio completada"
    log_success "=========================================="
    log_info "Archivo de configuración: $ASOUND_FILE"
    log_info "Backup guardado en: $BACKUP_DIR"
    log_info "Log guardado en: $LOG_FILE"
    log_info ""
    log_info "Comandos útiles:"
    log_info "  - Ver tarjetas de audio: aplay -l"
    log_info "  - Controlar volumen: alsamixer"
    log_info "  - Probar audio: speaker-test -D default -c 2 -t wav"
    log_info "  - Ver dispositivos PCM: aplay -L"
    log_info ""
    
    if ! groups "$USER" | grep -q "\baudio\b" 2>/dev/null; then
        log_warning "⚠️  IMPORTANTE: Debes cerrar sesión y volver a entrar para que el grupo 'audio' tome efecto."
    fi
    
    log_info "Si el audio no funciona, reinicia el sistema con: sudo reboot"
}

################################################################################
# Main
################################################################################

main() {
    clear
    log_info "=========================================="
    log_info "Audio Setup para Orange Pi Zero 3"
    log_info "Configuración ALSA + HDMI"
    log_info "=========================================="
    log_info ""
    
    # Verificaciones iniciales
    check_root
    check_sudo
    check_dependencies
    
    # Preguntar si continuar
    if [ $INTERACTIVE -eq 1 ]; then
        read -r -p "¿Deseas continuar con la configuración? (s/n): " response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            log_info "Configuración cancelada por el usuario."
            exit 0
        fi
    fi
    
    # Crear backup
    create_backup
    
    # Ejecutar configuración
    remove_pulseaudio
    remove_pipewire
    add_user_to_audio_group
    detect_hdmi_card
    generate_asoundrc
    test_audio
    
    # Mostrar información final
    show_final_info
}

# Procesar argumentos
while getopts "nh" opt; do
    case $opt in
        n)
            INTERACTIVE=0
            ;;  
        h)
            echo "Uso: $0 [-n] [-h]"
            echo "  -n  Modo no interactivo (sin confirmaciones)"
            echo "  -h  Mostrar esta ayuda"
            exit 0
            ;;  
        \?)
            echo "Opción inválida: -$OPTARG" >&2
            exit 1;
            ;;  
    esac
done

# Ejecutar
main