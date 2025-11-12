#!/bin/bash

# -----------------------------------
# Bootstrap Installer para Orange Pi Zero 3 Scripts
# -----------------------------------

set -e

# Lista de scripts a preparar
SCRIPTS=(
  "audio_setup.sh"
  "lxde_installer.sh"
  "mupen64plus_build.sh"
  "duckstation_setup.sh"
)

# Dar permisos de ejecución
echo "🔐 Aplicando permisos de ejecución..."
for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    chmod +x "$script"
    echo "✅ Permisos listos: $script"
  else
    echo "⚠ No se encontró $script (puede que falte en el repo)"
  fi
done

echo ""
echo "🚀 Instalación básica completada."
echo "Puedes ejecutar manualmente los scripts:"
for script in "${SCRIPTS[@]}"; do
  echo "  ./$(basename "$script")"
done

# Opcional: lanzar menú interactivo
echo ""
echo "¿Deseas ejecutar alguno de los scripts ahora?"
select opcion in "${SCRIPTS[@]}" "Salir"; do
  case $REPLY in
    1|2|3|4) ./"${SCRIPTS[$REPLY-1]}"; break ;;
    5) echo "Saliendo."; break ;;
    *) echo "Opción inválida." ;;
  esac
done

echo "✅ Bootstrap finalizado correctamente."
