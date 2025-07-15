#!/bin/bash

# Carpeta de instalación
CARPETA="$HOME/emuladores"
APPIMAGE="DuckStation-arm64.AppImage"
ESCRITORIO="$HOME/.local/share/applications/duckstation.desktop"
ICONO_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Logo_Duckstation.svg/512px-Logo_Duckstation.svg.png"
ICONO="$HOME/.local/share/icons/duckstation.png"

echo "📁 Verificando carpeta $CARPETA..."
mkdir -p "$CARPETA"

echo "🌐 Descargando última versión de DuckStation para ARM64..."
LATEST_URL=$(curl -s https://api.github.com/repos/stenzek/duckstation/releases/latest \
  | grep "browser_download_url" | grep "$APPIMAGE" | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "❌ No se pudo encontrar la última versión. Verifica conexión o formato."
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

# Opcional: Forzar actualización de cachés de íconos y accesos
update-desktop-database ~/.local/share/applications >/dev/null 2>&1 || true
gtk-update-icon-cache ~/.local/share/icons >/dev/null 2>&1 || true

echo "✅ DuckStation instalado en $CARPETA y accesible desde el menú de aplicaciones."
echo "🎮 Puedes ejecutarlo desde el menú o con: $CARPETA/$APPIMAGE"
