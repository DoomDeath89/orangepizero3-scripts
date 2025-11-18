#!/bin/bash

# Script optimizado para desactivar PulseAudio/PipeWire y configurar ALSA puro (HDMI) en Orange Pi Zero 3

ASOUND_FILE="$HOME/.asoundrc"

remove_pulseaudio() {
    echo "🔎 Verificando si PulseAudio está instalado..."
    if command -v pulseaudio >/dev/null 2>&1; then
        echo "⚠ PulseAudio detectado. Procediendo a eliminar..."
        systemctl --user stop pulseaudio.socket pulseaudio.service 2>/dev/null
        systemctl --user disable pulseaudio.socket pulseaudio.service 2>/dev/null
        sudo apt remove --purge -y pulseaudio
        sudo apt autoremove -y
        rm -rf ~/.config/pulse
        echo "✅ PulseAudio eliminado."
    else
        echo "✅ PulseAudio no está instalado."
    fi
}

remove_pipewire() {
    echo "🔎 Verificando si PipeWire está instalado..."
    if command -v pipewire >/dev/null 2>&1; then
        echo "⚠ PipeWire detectado. Procediendo a eliminar..."
        systemctl --user stop pipewire pipewire-pulse 2>/dev/null
        systemctl --user disable pipewire pipewire-pulse 2>/dev/null
        sudo apt remove --purge -y pipewire pipewire-audio-client-libraries libpipewire* wireplumber
        sudo apt autoremove -y
        rm -rf ~/.config/pipewire
        echo "✅ PipeWire eliminado."
    else
        echo "✅ PipeWire no está instalado."
    fi
}

add_user_to_audio_group() {
    echo "➕ Asegurando que el usuario pertenece al grupo 'audio'..."
    sudo usermod -aG audio "$USER"
}

detect_hdmi_card() {
    echo "🔍 Detectando tarjeta HDMI..."
    HDMI_CARD=$(aplay -l | grep -i "HDMI" | head -n1 | awk -F: '{print $1}' | awk '{print $2}')
    
    if [ -z "$HDMI_CARD" ]; then
        echo "❌ No se detectó salida HDMI. Verifica con 'aplay -l'."
        exit 1
    fi

    echo "✅ HDMI detectado como tarjeta $HDMI_CARD"
}

generate_asoundrc() {
    echo "🛠 Generando archivo .asoundrc con HDMI card $HDMI_CARD..."

    cat > "$ASOUND_FILE" << EOF
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
EOF
    echo "✅ Archivo .asoundrc configurado con éxito."
}

test_audio() {
    echo "🔊 Realizando prueba de audio..."
    speaker-test -D default -c 2 -t wav -l 1
}

# Ejecutar
remove_pulseaudio
remove_pipewire
add_user_to_audio_group
detect_hdmi_card
generate_asoundrc
test_audio

echo -e "\n✅ Configuración completa."
echo "ℹ️ Reinicia el sistema si el audio aún no funciona para asegurarte de que los servicios eliminados no se reactiven."
