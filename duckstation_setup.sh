#!/bin/bash

# Obtener el home del usuario real (en caso de usar sudo)
REAL_USER_HOME=$(eval echo "~$SUDO_USER")
CARPETA="${REAL_USER_HOME:-$HOME}/emuladores"
APPIMAGE="DuckStation-arm64.AppImage"
ESCRITORIO="$REAL_USER_HOME/.local/share/applications/juegos/duckstation.desktop"
ICONO_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Logo_Duckstation.svg/512px-Logo_Duckstation.svg.png"
ICONO="$REAL_USER_HOME/.local/share/icons/duckstation.png"

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

chmod +x "$ESCRITORIO"

# Actualizar bases de datos de íconos y accesos
sudo -u "$SUDO_USER" update-desktop-database "$REAL_USER_HOME/.local/share/applications" >/dev/null 2>&1 || true
sudo -u "$SUDO_USER" gtk-update-icon-cache "$REAL_USER_HOME/.local/share/icons" >/dev/null 2>&1 || true

echo "✅ DuckStation instalado en $CARPETA y accesible desde el menú."
echo "🎮 Ejecuta desde el menú o manualmente con: $CARPETA/$APPIMAGE"
