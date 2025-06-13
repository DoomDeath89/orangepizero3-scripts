#!/bin/bash

# Script Full: Configuración de audio optimizada para Orange Pi Zero 3 (HDMI, ALSA puro)
# Elimina pulseaudio, pipewire y configura dmix para permitir múltiples aplicaciones simultáneas.

ASOUND_FILE="$HOME/.asoundrc"

# Función para desinstalar pulseaudio si existe
remove_pulseaudio() {
    echo "🔎 Verificando si PulseAudio está instalado..."
    if command -v pulseaudio >/dev/null 2>&1; then
        echo "⚠ PulseAudio detectado. Procediendo a desinstalar..."
        sudo systemctl --user stop pulseaudio.socket pulseaudio.service 2>/dev/null
        sudo systemctl --user disable pulseaudio.socket pulseaudio.service 2>/dev/null
        sudo apt-get remove --purge -y pulseaudio
        sudo apt-get autoremove -y
        rm -rf ~/.config/pulse
        echo "✅ PulseAudio desinstalado correctamente."
    else
        echo "✅ PulseAudio no está instalado."
    fi
}

# Función para desinstalar pipewire si existe
remove_pipewire() {
    echo "🔎 Verificando si PipeWire está instalado..."
    if command -v pipewire >/dev/null 2>&1; then
        echo "⚠ PipeWire detectado. Procediendo a desinstalar..."
        sudo systemctl --user stop pipewire pipewire-pulse 2>/dev/null
        sudo systemctl --user disable pipewire pipewire-pulse 2>/dev/null
        sudo apt-get remove --purge -y pipewire pipewire-audio-client-libraries
        sudo apt-get autoremove -y
        rm -rf ~/.config/pipewire
        echo "✅ PipeWire desinstalado correctamente."
    else
        echo "✅ PipeWire no está instalado."
    fi
}

# Verificamos que la tarjeta HDMI esté presente
verify_hdmi() {
    echo "🔎 Detectando tarjetas de sonido..."
    aplay -l

    if ! aplay -l | grep -q "card 1.*HDMI"; then
        echo "⚠ No se detecta tarjeta HDMI en card 1. Verifica manualmente con 'aplay -l'"
        exit 1
    fi
}

# Generar el archivo .asoundrc con dmix optimizado
generate_asoundrc() {
    echo "🔧 Generando configuración ALSA optimizada en $ASOUND_FILE"
    cat > "$ASOUND_FILE" << EOF
pcm.!default {
    type plug
    slave.pcm "hdmi_dmix"
}

pcm.hdmi_dmix {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:1,0"
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
    card 1
}
EOF
    echo "✅ Archivo .asoundrc generado correctamente."
}

# Probar el audio
test_audio() {
    echo "🔊 Realizando prueba de audio con speaker-test..."
    speaker-test -D default -c 2 -t wav -l 1
}

# Ejecutar las funciones
remove_pulseaudio
remove_pipewire
verify_hdmi
generate_asoundrc
test_audio

echo "✅ Configuración de audio ALSA finalizada. El sistema está listo para usar múltiples aplicaciones de audio simultáneamente."
echo "ℹ Si algo falla, reinicia el sistema para asegurar que los servicios eliminados no se reactiven."
