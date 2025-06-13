#!/bin/bash

set -e

echo "🔄 Actualizando repositorios e instalando dependencias necesarias..."

if ! command -v sudo &> /dev/null; then
  echo "❗ No se encontró sudo. Ejecuta este script con root o instala sudo."
  exit 1
fi

sudo apt update
sudo apt install -y build-essential git libsdl2-dev libpng-dev libfreetype6-dev nasm \
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

export M64P_PATH=$BASE_DIR

for dir in mupen64plus-*; do
  echo "Compilando $dir..."
  cd "$dir"
  
  if [ "$dir" == "mupen64plus-core" ]; then
    # Compilar en la raíz (donde está el Makefile)
    if [ -f Makefile ]; then
      make clean || true
      make all -j$(nproc)
    else
      echo "⚠ No se encontró Makefile en $dir, saltando compilación."
    fi
    cd ..
  else
    # Para los otros, compilar en projects/unix
    if [ -d "projects/unix" ]; then
      cd projects/unix
      if [ -f Makefile ]; then
        make clean || true
        make all -j$(nproc)
      else
        echo "⚠ No se encontró Makefile en $dir/projects/unix, saltando."
      fi
      cd ../../
    else
      echo "⚠ No existe carpeta projects/unix en $dir, saltando."
    fi
  fi
done

read -p "¿Deseas instalar los binarios en /usr/local? (s/n): " INSTALAR

if [[ "$INSTALAR" =~ ^[sS]$ ]]; then
  for dir in mupen64plus-*; do
    echo "Instalando $dir..."
    cd "$dir"
    
    if [ "$dir" == "mupen64plus-core" ]; then
      if [ -f Makefile ]; then
        sudo make install
      else
        echo "⚠ No se encontró Makefile en $dir, saltando instalación."
      fi
      cd ..
    else
      if [ -d "projects/unix" ] && [ -f "projects/unix/Makefile" ]; then
        cd projects/unix
        sudo make install
        cd ../../
      else
        echo "⚠ No se pudo instalar $dir (Makefile o carpeta no encontrada)."
      fi
    fi
  done
fi

echo "✅ Mupen64Plus compilado e instalado exitosamente en ARM64."
