#!/bin/bash

# Script para monitorear logs de dispositivos en tiempo real
# Universidad

echo "=== MONITOREO DE LOGS DE RED EN TIEMPO REAL ==="
echo "Presiona Ctrl+C para salir"
echo

# Función para mostrar logs de un dispositivo
show_device_logs() {
    local device=$1
    local ip=$2
    local logfile="/var/log/network/$ip.log"
    
    if [ -f "$logfile" ]; then
        echo "--- $device ($ip) ---"
        tail -2 "$logfile" | while read line; do
            # Colorear según tipo de log
            if [[ "$line" == *"ERROR"* ]] || [[ "$line" == *"CRITICAL"* ]]; then
                echo -e "\033[0;31m$line\033[0m"
            elif [[ "$line" == *"WARNING"* ]] || [[ "$line" == *"WARN"* ]]; then
                echo -e "\033[0;33m$line\033[0m"
            else
                echo -e "\033[0;32m$line\033[0m"
            fi
        done
        echo
    fi
}

# Monitoreo continuo
while true; do
    clear
    echo "=== LOGS DE RED - $(date) ==="
    echo
    
    # Mostrar logs de dispositivos principales
    show_device_logs "R1" "192.168.1.241"
    show_device_logs "R3" "172.16.0.1"
    show_device_logs "Switch7" "172.16.0.2"
    
    sleep 5
done
