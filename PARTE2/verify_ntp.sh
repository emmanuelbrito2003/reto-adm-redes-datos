#!/bin/bash

echo "=== VERIFICANDO NTP Y HORA EN DISPOSITIVOS ==="
echo

devices=(
    "192.168.1.241:R1"
    "192.168.0.1:R2"
    "172.16.0.1:R3"
    "172.16.0.2:Switch7"
)

for device in "${devices[@]}"; do
    IFS=':' read -ra DEV <<< "$device"
    ip=${DEV[0]}
    name=${DEV[1]}
    
    echo "--- $name ($ip) ---"
    
    # Verificar hora y NTP
    sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no admin@$ip << 'CISCO'
enable
cisco
show clock
show ntp status
exit
CISCO
    echo
done

echo "=== VERIFICACIÓN COMPLETADA ==="
