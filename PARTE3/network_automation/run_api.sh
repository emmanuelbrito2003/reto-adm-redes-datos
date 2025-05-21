#!/bin/bash

# Script para ejecutar la API REST de Administración de Red
# Universidad - Parte III

# Directorio base
BASE_DIR="/root/network_automation"
VENV_DIR="/root/venv/network_env"

# Activar entorno virtual
source "$VENV_DIR/bin/activate"

# Verificar que el entorno virtual está activado
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Error: No se pudo activar el entorno virtual"
    exit 1
fi

# Verificar que el directorio base existe
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: El directorio base no existe: $BASE_DIR"
    exit 1
fi

# Crear directorios si no existen
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/backups"

# Verificar que app.py existe
if [ ! -f "$BASE_DIR/api/app.py" ]; then
    echo "Error: No se encuentra app.py en $BASE_DIR/api"
    exit 1
fi

# Establecer permisos de ejecución
chmod +x "$BASE_DIR/api/app.py"

# Iniciar la API
echo "Iniciando API REST en http://0.0.0.0:5000"
echo "Presiona Ctrl+C para detener"
cd "$BASE_DIR"
python "$BASE_DIR/api/app.py"
