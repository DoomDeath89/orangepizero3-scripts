# Orange Pi Zero 3 - Linux ARM64 Fixes

Este repositorio está dedicado a documentar, desarrollar y compartir **scripts, configuraciones, parches y soluciones** para mejorar el funcionamiento de la placa **Orange Pi Zero 3** utilizando distribuciones Linux ARM64 (como Armbian, Debian, Ubuntu Server, etc).


## Objetivo

- Facilitar la configuración inicial del sistema.  
- Resolver problemas comunes de compatibilidad en audio, video, red, drivers, etc.  
- Automatizar instalaciones de paquetes gráficos y de sistema.  
- Proveer scripts para optimización de recursos (RAM, CPU, almacenamiento).  
- Recopilar soluciones a errores encontrados en el uso diario de Orange Pi Zero 3 bajo Linux ARM64.

---

## Contenido

- Scripts de instalación/desinstalación de entornos gráficos livianos (LXDE, Xorg, LightDM).  
- Fixes de audio (HDMI, ALSA, PulseAudio).  
- Configuraciones personalizadas para minimizar el uso de recursos.  
- Ejemplos de compilación de paquetes para ARM64.  
- Soluciones a problemas de dependencias.

---

## Público objetivo

- Usuarios de Orange Pi Zero 3  
- Entusiastas de SBC (Single Board Computers)  
- Desarrolladores ARM64  
- Cualquier persona buscando mejorar el rendimiento o estabilidad de su sistema en esta plataforma.

---

## Instalación

Sigue estos pasos para clonar el repositorio y ejecutar el instalador:

```bash
# Clonar el repositorio
git clone https://github.com/DoomDeath89/orangepizero3-scripts.git

# Acceder al directorio del proyecto
cd orangepizero3-scripts

# Dar permisos de ejecución al script de instalación
chmod +x bootstrap_installer.sh

# Ejecutar el script con privilegios de administrador
sudo ./bootstrap_installer.sh
```

---

## Notas

- Este proyecto es comunitario y está en constante evolución.  
- Si tienes aportes, sugerencias o fixes adicionales, ¡son bienvenidos vía pull request o issues!

---

## Autor

Gustavo Burgos

---

## Plataforma

Orange Pi Zero 3 - ARM64

---

## Licencia

MIT
