#!/bin/bash

set -euo pipefail

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de mensaje
info() { echo -e "${BLUE}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warning() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✗ ${NC}$1"; exit 1; }

# Verificar arquitectura
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
  warning "Este script está diseñado para ARM64 (aarch64), pero se está ejecutando en $ARCH"
  read -p "¿Deseas continuar de todos modos? (s/n): " CONTINUAR
  [[ "$CONTINUAR" =~ ^[sS]$ ]] || error "Ejecución cancelada"
fi

# Verificar sudo
if ! command -v sudo &> /dev/null; then
  if [ "$(id -u)" -eq 0 ]; then
    sudo() { "$@"; } # Si ya somos root, sudo es redundante
  else
    error "sudo no encontrado y no se está ejecutando como root"
  fi
fi

# Instalar dependencias
info "🔄 Actualizando e instalando dependencias..."
sudo apt update && sudo apt install -y \
  libvulkan-dev build-essential git libsdl2-dev libpng-dev libfreetype6-dev nasm \
  libglib2.0-dev libxi-dev libxext-dev libxrandr-dev libasound2-dev libpulse-dev \
  libspeexdsp-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev cmake || error "Fallo al instalar dependencias"

# Configurar directorio base
BASE_DIR="$HOME/mupen64plus-arm64"
mkdir -p "$BASE_DIR" || error "No se pudo crear $BASE_DIR"
cd "$BASE_DIR" || error "No se pudo acceder a $BASE_DIR"

# Repositorios necesarios
REPOS=(
  "https://github.com/mupen64plus/mupen64plus-core.git"
  "https://github.com/mupen64plus/mupen64plus-ui-console.git"
  "https://github.com/mupen64plus/mupen64plus-audio-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-input-sdl.git"
  "https://github.com/mupen64plus/mupen64plus-video-glide64mk2.git"
  "https://github.com/mupen64plus/mupen64plus-rsp-hle.git"
)

# Clonar/actualizar repositorios
for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO" .git)
  if [ ! -d "$REPO_NAME" ]; then
    info "Clonando $REPO_NAME..."
    git clone --depth=1 --single-branch "$REPO" || warning "Fallo al clonar $REPO_NAME"
  else
    info "Actualizando $REPO_NAME..."
    cd "$REPO_NAME" || { warning "No se pudo acceder a $REPO_NAME"; continue; }
    git pull || warning "Fallo al actualizar $REPO_NAME"
    cd "$BASE_DIR"
  fi
done

export M64P_PATH="$BASE_DIR"

# Función para compilar módulos
compile_modules() {
  local failed=0
  for dir in mupen64plus-*; do
    if [ -d "$dir" ]; then
      cd "$dir" || { warning "No se pudo entrar a $dir"; ((failed++)); continue; }
      
      if [ -d "projects/unix" ] && [ -f "projects/unix/Makefile" ]; then
        info "Compilando $dir..."
        cd projects/unix || { warning "No se pudo acceder a projects/unix"; ((failed++)); cd "$BASE_DIR"; continue; }
        
        make clean || true
        if make all -j$(nproc); then
          success "$dir compilado correctamente"
        else
          warning "Fallo al compilar $dir"
          ((failed++))
        fi
      else
        warning "Makefile no encontrado en $dir/projects/unix"
        ((failed++))
      fi
      
      cd "$BASE_DIR"
    fi
  done
  return $failed
}

# Función para instalar módulos
install_modules() {
  local failed=0
  for dir in mupen64plus-*; do
    if [ -d "$dir" ]; then
      cd "$dir" || { warning "No se pudo entrar a $dir"; ((failed++)); continue; }
      
      if [ -d "projects/unix" ] && [ -f "projects/unix/Makefile" ]; then
        info "Instalando $dir..."
        cd projects/unix || { warning "No se pudo acceder a projects/unix"; ((failed++)); cd "$BASE_DIR"; continue; }
        
        if sudo make install; then
          success "$dir instalado correctamente"
        else
          warning "Fallo al instalar $dir"
          ((failed++))
        fi
      else
        warning "Makefile no encontrado en $dir/projects/unix"
        ((failed++))
      fi
      
      cd "$BASE_DIR"
    fi
  done
  return $failed
}

# Menú principal
PS3="Selecciona una opción: "
options=("Compilar e instalar todo" "Solo compilar" "Solo instalar" "Salir")
select opt in "${options[@]}"
do
  case $opt in
    "Compilar e instalar todo")
      compile_modules || warning "Algunos módulos fallaron al compilar"
      install_modules || warning "Algunos módulos fallaron al instalar"
      break
      ;;
    "Solo compilar")
      compile_modules || warning "Algunos módulos fallaron al compilar"
      break
      ;;
    "Solo instalar")
      install_modules || warning "Algunos módulos fallaron al instalar"
      break
      ;;
    "Salir")
      info "Saliendo..."
      exit 0
      ;;
    *) 
      warning "Opción inválida"
      ;;
  esac
done

success "✅ Proceso completado. Ejecuta 'mupen64plus' para iniciar el emulador."
