#!/bin/bash

# Detectar usuario real
if [ -n "$SUDO_USER" ]; then
  REAL_USER="$SUDO_USER"
else
  REAL_USER="$USER"
fi
REAL_USER_HOME=$(eval echo "~$REAL_USER")

CARPETA="$REAL_USER_HOME/emuladores"
APPIMAGE="DuckStation-arm64.AppImage"
ESCRITORIO="$REAL_USER_HOME/.local/share/applications/juegos/duckstation.desktop"
ICONO_URL="https://raw.githubusercontent.com/DoomDeath89/orangepizero3-scripts/new_scrips/icons/Logo_Duckstation.svg.png"
ICONO="$REAL_USER_HOME/.local/share/icons/duckstation.png"

echo "Usuario real: $REAL_USER"
echo "Home real: $REAL_USER_HOME"

echo "📁 Creando carpeta: $CARPETA"
mkdir -p "$CARPETA"

echo "🌐 Descargando última versión de DuckStation para ARM64..."
LATEST_URL=$(curl -s https://api.github.com/repos/stenzek/duckstation/releases/latest \
  | grep "browser_download_url" | grep "$APPIMAGE" | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "❌ No se pudo encontrar la última versión. Verifica conexión o nombre del archivo."
    exit 1
fi

wget -O "$CARPETA/$APPIMAGE" "$LATEST_URL"
chmod +x "$CARPETA/$APPIMAGE"

echo "🖼 Descargando icono..."
mkdir -p "$(dirname "$ICONO")"
wget -O "$ICONO" "$ICONO_URL"

echo "🖥 Creando acceso directo en el menú de aplicaciones..."
mkdir -p "$(dirname "$ESCRITORIO")"

cat > "$ESCRITORIO" <<EOF
[Desktop Entry]
Name=DuckStation (ARM64)
Exec=$CARPETA/$APPIMAGE
Icon=$ICONO
Type=Application
Categories=Game;Emulator;
Comment=PlayStation 1 emulator
Terminal=false
EOF

# chmod 644 para archivos .desktop es suficiente
chmod 644 "$ESCRITORIO"

# Cambiar dueño solo si el script fue corrido con sudo
if [ "$REAL_USER" != "$USER" ]; then
  chown "$REAL_USER":"$REAL_USER" "$ESCRITORIO" "$ICONO"
fi

echo "✅ DuckStation instalado en $CARPETA y accesible desde el menú."
echo "🎮 Ejecuta desde el menú o manualmente con: $CARPETA/$APPIMAGE"

# Mensaje para refrescar sesión o entorno gráfico
echo "ℹ️ Si no ves DuckStation en el menú, prueba a cerrar y abrir sesión o reiniciar tu entorno gráfico."
