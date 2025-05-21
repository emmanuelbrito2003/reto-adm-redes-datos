# reto-adm-redes-datos
Proyecto de reto final de administración de redes de datos 

🌐 Proyecto: Administración de Redes de Datos

Este repositorio contiene la implementación completa del proyecto "Reto Final" para la asignatura de Administración de Redes de Datos. El proyecto desarrolla una infraestructura de red empresarial desde la configuración básica hasta la automatización programática.

🔄 Topología de Red



📋 Descripción del Proyecto

El proyecto está estructurado en tres partes progresivas:

🏗️ Parte I: Infraestructura Básica

Topología jerárquica de 3 capas (Core, Distribution, Access)
Configuración de enrutamiento dinámico con OSPFv2
Segmentación mediante VLANs y Router-on-a-Stick
Implementación de NAT para acceso a Internet
Acceso SSH en todos los dispositivos

📊 Parte II: Monitoreo y Administración

Implementación de SNMP para monitoreo centralizado
Servidor NTP para sincronización horaria
Centralización de logs mediante Syslog
Dashboard de monitoreo con Zabbix

⚙️ Parte III: Automatización

Scripts Python para tareas administrativas (backups, tests)
API REST para gestión programática
Despliegue como servicio systemd
Integración con infraestructura existente

💻 Tecnologías Utilizadas

Redes: OSPFv2, VLANs, NAT, Router-on-a-Stick
Monitoreo: SNMP, NTP, Syslog, Zabbix
Automatización: Python, Flask, API REST
Servicios: systemd, rsyslog, chrony

📁 Estructura del Repositorio

├── parte1/             # Configuraciones de equipos de red

├── parte2/             # Scripts de monitoreo y configuración Zabbix

├── parte3/             # Scripts Python y API REST

├── docs/               # Documentación adicional

└── img/                # Imágenes para documentación
📋 Requisitos

Dispositivos Cisco (físicos o simulados en GNS3/EVE-NG/Packet Tracer)
Servidor Linux para Zabbix y servicios REST
Python 3.6+ con bibliotecas (netmiko, flask, pyyaml)

🚀 Instalación

Clonar este repositorio
Aplicar las configuraciones de la parte1 a los dispositivos correspondientes
Configurar el servidor Zabbix según instrucciones en parte2
Desplegar la API REST siguiendo los pasos en parte3/README.md

👨‍💻 Autores
Emmanuel Brito, Miguel Alvarez, Carlos Centeno

Universidad Católica de Cuenca - Administración de Redes de Datos - 2025
