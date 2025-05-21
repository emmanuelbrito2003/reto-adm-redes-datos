#!/bin/bash

# Script mejorado para test de syslog
# Simula logs viniendo de dispositivos específicos

if [ $# -lt 1 ]; then
    echo "Uso: $0 <dispositivo> [mensaje]"
    echo "Dispositivos disponibles: R1, R2, R3, Switch5, Switch6, Switch7, Switch8, Switch9"
    exit 1
fi

DEVICE=$1
MESSAGE=${2:-"Test log from $DEVICE"}

# IPs de dispositivos
declare -A DEVICE_IPS
DEVICE_IPS[R1]="192.168.1.241"
DEVICE_IPS[R2]="192.168.0.1"
DEVICE_IPS[R3]="192.168.1.246"
DEVICE_IPS[Switch5]="172.16.0.4"
DEVICE_IPS[Switch6]="172.16.0.3"
DEVICE_IPS[Switch7]="172.16.0.2"
DEVICE_IPS[Switch8]="192.168.0.130"
DEVICE_IPS[Switch9]="192.168.0.2"

IP=${DEVICE_IPS[$DEVICE]}

if [ -z "$IP" ]; then
    echo "Dispositivo $DEVICE no reconocido"
    exit 1
fi

echo "Enviando log de prueba..."
echo "Dispositivo: $DEVICE"
echo "IP simulada: $IP"
echo "Mensaje: $MESSAGE"

# Crear log con formato realistic
LOG_ENTRY="<165>$(date +'%b %d %H:%M:%S') $DEVICE: %SYS-5-CONFIG_I: Configured from console by admin on vty0 - $MESSAGE"

# Enviar usando nc
if command -v nc >/dev/null 2>&1; then
    echo "$LOG_ENTRY" | nc -u -w1 172.16.0.10 514
    echo "✓ Log enviado"
    
    # Verificar después de 2 segundos
    sleep 2
    echo
    echo "Verificando archivo /var/log/network/$DEVICE.log:"
    tail -3 /var/log/network/$DEVICE.log 2>/dev/null || echo "Archivo no encontrado aún"
else
    echo "Error: nc no está disponible"
    exit 1
fi
