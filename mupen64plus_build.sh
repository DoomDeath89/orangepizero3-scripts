#!/bin/bash

set -e

echo "🔄 Actualizando repositorios e instalando dependencias necesarias..."

if ! command -v sudo &> /dev/null; then
  echo "❗ No se encontró sudo. Ejecuta este script con root o instala sudo."
  exit 1
fi

sudo apt update
sudo apt install -y libvulkan-dev build-essential git libsdl2-dev libpng-dev libfreetype6-dev nasm \
  libglib2.0-dev libxi-dev libxext-dev libxrandr-dev libasound2-dev libpulse-dev \
  libspeexdsp-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev cmake

BASE_DIR=$HOME/mupen64plus-arm64

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

REPOS=(
  "https://github.com/mupen64plus/mupen64plus-core.git"
  "https://github.com/mupen64plus/mupen64plus-ui-console.git"
  "https://github.com/mupen64plus/mupen64plus-audio-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-input-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-video-glide64mk2.git"
  "https://github.com/mupen64plus/mupen64plus-rsp-hle.git"
)

# Clonar o actualizar repositorios
for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO" .git)
  if [ ! -d "$REPO_NAME" ]; then
    echo "Clonando $REPO_NAME..."
    git clone --depth=1 "$REPO"
  else
    echo "Repositorio $REPO_NAME ya existe, actualizando..."
    cd "$REPO_NAME"
    git pull
    cd "$BASE_DIR"
  fi
done

export M64P_PATH=$BASE_DIR

# Compilar repos
for dir in mupen64plus-*; do
  echo "Compilando $dir..."
  cd "$BASE_DIR"

  if [ -d "$dir/projects/unix" ] && [ -f "$dir/projects/unix/Makefile" ]; then
    cd "$dir/projects/unix"
    echo "Ejecutando make clean en $dir..."
    make clean || true
    echo "Compilando $dir con make all..."
    make all -j$(nproc)
  else
    echo "⚠ No se encontró Makefile en $dir/projects/unix, saltando compilación."
  fi
done

# Preguntar si desea instalar
read -p "¿Deseas instalar los binarios en /usr/local? (s/n): " INSTALAR

if [[ "$INSTALAR" =~ ^[sS]$ ]]; then
  for dir in mupen64plus-*; do
    echo "Instalando $dir..."
    cd "$BASE_DIR"

    if [ -d "$dir/projects/unix" ] && [ -f "$dir/projects/unix/Makefile" ]; then
      cd "$dir/projects/unix"
      sudo make install
    else
      echo "⚠ No se encontró Makefile en $dir/projects/unix, saltando instalación."
    fi
  done
fi

echo "✅ Mupen64Plus compilado e instalado exitosamente en ARM64."