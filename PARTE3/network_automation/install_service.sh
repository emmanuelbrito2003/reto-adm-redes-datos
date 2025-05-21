#!/bin/bash

# Script para instalar y configurar el servicio de API REST
# Universidad - Parte III

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Verificar que se ejecute como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Este script debe ejecutarse como root${NC}"
  exit 1
fi

# Variables de entorno
VENV_DIR="/root/venv/network_env"
BASE_DIR="/root/network_automation"
SERVICE_NAME="network-api.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"

echo -e "${YELLOW}=== Instalación del servicio API REST ===${NC}"
echo

# 1. Verificar que app.py existe
if [ ! -f "$BASE_DIR/api/app.py" ]; then
    echo -e "${RED}Error: No se encuentra app.py en $BASE_DIR/api${NC}"
    exit 1
fi

# 2. Verificar que el entorno virtual existe
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}Error: No se encuentra el entorno virtual en $VENV_DIR${NC}"
    exit 1
fi

# 3. Crear archivo de servicio systemd
echo -e "${YELLOW}Creando archivo de servicio systemd...${NC}"

cat > $SERVICE_FILE << EOF
[Unit]
Description=API REST para Administración de Red - Universidad
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BASE_DIR
ExecStart=$VENV_DIR/bin/python3 $BASE_DIR/api/app.py
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=network-api

[Install]
WantedBy=multi-user.target
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No se pudo crear el archivo de servicio${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Archivo de servicio creado: $SERVICE_FILE${NC}"

# 4. Establecer permisos
chmod 644 $SERVICE_FILE

# 5. Recargar systemd
echo -e "${YELLOW}Recargando configuración de systemd...${NC}"
systemctl daemon-reload

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No se pudo recargar systemd${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuración de systemd recargada${NC}"

# 6. Habilitar e iniciar el servicio
echo -e "${YELLOW}Habilitando el servicio para inicio automático...${NC}"
systemctl enable $SERVICE_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No se pudo habilitar el servicio${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Servicio habilitado para inicio automático${NC}"

echo -e "${YELLOW}Iniciando el servicio...${NC}"
systemctl start $SERVICE_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No se pudo iniciar el servicio${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Servicio iniciado correctamente${NC}"

# 7. Verificar estado
echo -e "${YELLOW}Verificando estado del servicio...${NC}"
systemctl status $SERVICE_NAME --no-pager

# 8. Resumen final
echo
echo -e "${GREEN}=== Instalación completada ===${NC}"
echo -e "El servicio API REST está configurado y en ejecución"
echo -e "Puedes acceder a la API en: http://$(hostname -I | awk '{print $1}'):5000"
echo
echo -e "${YELLOW}Comandos útiles:${NC}"
echo -e "- Ver estado: ${GREEN}systemctl status $SERVICE_NAME${NC}"
echo -e "- Reiniciar: ${GREEN}systemctl restart $SERVICE_NAME${NC}"
echo -e "- Ver logs: ${GREEN}journalctl -u $SERVICE_NAME -f${NC}"
echo

exit 0
