#!/bin/bash

set -e

# Instalar dependencias necesarias para compilar mupen64plus en ARM64
echo "🔄 Actualizando repositorios e instalando dependencias..."
if ! command -v sudo &> /dev/null; then
  echo "❗ No se encontró sudo. Ejecuta este script con root o instala sudo."
  exit 1
fi

sudo apt update
sudo apt install -y build-essential git libsdl2-dev libpng-dev libfreetype6-dev nasm \
  libglib2.0-dev libxi-dev libxext-dev libxrandr-dev libasound2-dev libpulse-dev

# Carpeta base donde vamos a clonar los repos
BASE_DIR=$HOME/mupen64plus-arm64

# Crear carpeta base si no existe
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Repositorios a clonar
REPOS=(
  "https://github.com/mupen64plus/mupen64plus-core.git"
  "https://github.com/mupen64plus/mupen64plus-ui-console.git"
  "https://github.com/mupen64plus/mupen64plus-audio-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-input-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-video-glide64mk2.git"
  "https://github.com/mupen64plus/mupen64plus-rsp-hle.git"
)

# Clonamos los repositorios si no existen
for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO" .git)
  if [ ! -d "$REPO_NAME" ]; then
    echo "Clonando $REPO_NAME..."
    git clone --depth=1 "$REPO"
  else
    echo "Repositorio $REPO_NAME ya existe, actualizando..."
    cd "$REPO_NAME"
    git pull
    cd ..
  fi
done

# Exportamos la ruta base (por si algún módulo lo necesita)
export M64P_PATH=$BASE_DIR

# Compilamos cada módulo
for dir in mupen64plus-*; do
  echo "Compilando $dir..."
  cd "$dir/projects/unix"
  make all -j$(nproc)
  cd ../../
done

# Preguntar si desea instalar
read -p "¿Deseas instalar los binarios en /usr/local? (s/n): " INSTALAR

if [[ "$INSTALAR" =~ ^[sS]$ ]]; then
  for dir in mupen64plus-*; do
    echo "Instalando $dir..."
    cd "$dir/projects/unix"
    sudo make install
    cd ../../
  done
fi

echo "✅ Mupen64Plus compilado e instalado exitosamente en ARM64."
