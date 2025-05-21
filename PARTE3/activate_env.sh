#!/bin/bash
# Script para activar entorno virtual de manera correcta
source /root/venv/network_env/bin/activate

# Configurar alias para python
alias python=python3

# Mostrar información del entorno
which python
python --version
pip --version

echo "Entorno virtual activado correctamente"
echo "Usar 'deactivate' para salir del entorno"
