#!/bin/bash

# Script Full Cleanup: Elimina completamente PulseAudio y PipeWire (64-bit y 32-bit)
# y configura ALSA puro con HDMI y dmix.
# Ideal para Orange Pi Zero 3 y otros dispositivos ARM.

ASOUND_FILE="$HOME/.asoundrc"

# Función para desinstalar todos los paquetes relacionados con PulseAudio y PipeWire
purge_audio_servers() {
    echo "🔎 Eliminando paquetes relacionados con PulseAudio y PipeWire (todos los arquitecturas)..."

    sudo systemctl --user stop pipewire pipewire.socket pipewire-pulse pulseaudio pulseaudio.socket 2>/dev/null
    sudo systemctl --user disable pipewire pipewire.socket pipewire-pulse pulseaudio pulseaudio.socket 2>/dev/null

    sudo apt purge -y \
        'pipewire*' \
        'pulseaudio*' \
        'libpipewire-*' \
        'libpulse*' \
        'libpulsedsp*' \
        'libspa-0.2-*' \
        'osspd-pulseaudio*'

    sudo dpkg -P $(dpkg -l | awk '/pipewire|pulseaudio/ && /:i386|:armhf/ {print $2}') 2>/dev/null

    echo "🧹 Limpiando configuraciones de usuario..."
    rm -rf ~/.config/pipewire ~/.config/pulse ~/.pulse* ~/.asoundrc

    echo "🧼 Limpiando el sistema..."
    sudo apt autoremove --purge -y
    sudo apt clean

    echo "✅ Todos los paquetes relacionados con PulseAudio y PipeWire han sido purgados."
}

# Quitar arquitecturas innecesarias (opcional)
remove_architectures() {
    echo "🔧 Verificando arquitecturas habilitadas..."
    for arch in i386 armhf; do
        if dpkg --print-foreign-architectures | grep -q "$arch"; then
            echo "❌ Eliminando soporte para arquitectura $arch..."
            sudo dpkg --remove-architecture $arch
        fi
    done
}

# Verificar presencia de tarjeta HDMI (card 1)
verify_hdmi() {
    echo "🔎 Detectando tarjetas de sonido..."
    aplay -l
    if ! aplay -l | grep -q "card 1.*HDMI"; then
        echo "⚠ No se detecta tarjeta HDMI en card 1. Verifica manualmente con 'aplay -l'"
        exit 1
    fi
}

# Generar configuración ALSA con dmix
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

# Prueba de audio
test_audio() {
    echo "🔊 Realizando prueba de audio con speaker-test..."
    speaker-test -D default -c 2 -t wav -l 1
}

# Ejecución principal
purge_audio_servers
remove_architectures
verify_hdmi
generate_asoundrc
test_audio

echo "✅ Configuración de audio ALSA finalizada."
echo "ℹ Reinicia el sistema para asegurar que todo funcione correctamente sin PulseAudio ni PipeWire."
