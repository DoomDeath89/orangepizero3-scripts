#!/bin/bash

set -e

# Carpeta base donde vamos a clonar los repos
BASE_DIR=$HOME/mupen64plus-arm64

# Crear carpeta base
mkdir -p $BASE_DIR
cd $BASE_DIR

# Repositorios a clonar
REPOS=(
  "https://github.com/mupen64plus/mupen64plus-core.git"
  "https://github.com/mupen64plus/mupen64plus-ui-console.git"
  "https://github.com/mupen64plus/mupen64plus-audio-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-input-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-video-glide64mk2.git"
  "https://github.com/mupen64plus/mupen64plus-rsp-hle.git"
)

# Clonamos los repositorios
for REPO in "${REPOS[@]}"; do
  git clone --depth=1 $REPO
done

# Exportamos la ruta base
export M64P_PATH=$BASE_DIR

# Compilamos cada módulo
for dir in mupen64plus-*; do
  echo "Compilando $dir..."
  cd $dir
  make all
  cd ..
done

# Instalación opcional (puede necesitar sudo)
echo "¿Deseas instalar los binarios en /usr/local? (s/n)"
read INSTALAR

if [ "$INSTALAR" == "s" ]; then
  for dir in mupen64plus-*; do
    cd $dir
    sudo make install
    cd ..
  done
fi

echo "✅ Mupen64Plus compilado exitosamente en ARM64."
