#!/bin/bash

# Nombre del script: lxde_installer.sh

# Función para instalar
install_lxde() {
    echo "Actualizando lista de paquetes..."
    sudo apt update

    echo "Instalando Xorg..."
    sudo apt install -y xorg

    echo "Instalando LightDM..."
    sudo apt install -y lightdm lightdm-gtk-greeter

    echo "Instalando LXDE..."
    sudo apt install -y lxde

    echo "Instalación completada."
}

# Función para desinstalar
uninstall_lxde() {
    echo "Desinstalando LXDE, Xorg y LightDM..."
    sudo apt purge -y lxde lightdm lightdm-gtk-greeter xorg
    sudo apt autoremove -y
    sudo apt autoclean

    echo "Desinstalación completada."
}

# Menú de opciones
echo "LXDE/Xorg/LightDM Installer"
echo "1) Instalar"
echo "2) Desinstalar"
echo "3) Salir"
read -p "Selecciona una opción: " option

case $option in
    1)
        install_lxde
        ;;
    2)
        uninstall_lxde
        ;;
    3)
        echo "Saliendo..."
        ;;
    *)
        echo "Opción inválida."
        ;;
esac
