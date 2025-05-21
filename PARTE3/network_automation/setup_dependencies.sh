#!/bin/bash

# Script para instalar dependencias necesarias para Parte III
# Universidad - Administración de Redes

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

echo -e "${BLUE}=== Instalando dependencias para automatización de red ===${NC}"

# Activar entorno virtual
source /root/venv/network_env/bin/activate

# Actualizar pip
echo -e "${YELLOW}Actualizando pip...${NC}"
pip install --upgrade pip

# Instalar dependencias principales
echo -e "${YELLOW}Instalando dependencias principales...${NC}"
pip install netmiko paramiko flask flask-restful pyyaml requests

# Instalar dependencias adicionales
echo -e "${YELLOW}Instalando dependencias adicionales...${NC}"
pip install pytest jinja2 pandas

# Verificar instalación
echo -e "${YELLOW}Verificando instalación...${NC}"
pip list

echo -e "${GREEN}✅ Dependencias instaladas correctamente${NC}"
echo -e "${BLUE}El entorno está listo para implementar scripts y API${NC}"
